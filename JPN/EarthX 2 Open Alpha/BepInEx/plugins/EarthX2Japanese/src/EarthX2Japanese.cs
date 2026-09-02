// EarthX 2 Japanese Localization Plugin v2
// - Registers a "Japanese" LocalizationAsset backed by StreamingAssets/Localization/Japanese
// - Adds a dynamic CJK fallback font so Japanese text renders in TextMeshPro
// - StringPatch: rewrites hardcoded ldstr strings in Assembly-CSharp.dll at JIT time
//   using rules from ja-strings*.tsv (SCOPE^^^ORIG^^^TRANS)
// - TextSweep: rewrites baked TMP_Text strings at runtime using ja-baked*.tsv (ORIG^^^TRANS)
// Compiled against the game's own assemblies with .NET Framework csc (C# 5 syntax).

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using BepInEx;
using BepInEx.Configuration;
using BepInEx.Logging;
using HarmonyLib;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace EarthX2Japanese
{
    [BepInPlugin("earthx2.japanese.localization", "EarthX 2 Japanese Localization", "1.0.0")]
    public class JapanesePlugin : BaseUnityPlugin
    {
        internal static ManualLogSource Log;
        internal static ConfigEntry<bool> ForceJapanese;
        internal static ConfigEntry<bool> AddFontFallback;
        internal static ConfigEntry<bool> TranslateHardcoded;

        private static int _sweepFrames;

        private void Awake()
        {
            Log = Logger;
            ForceJapanese = Config.Bind("General", "ForceJapanese", true, "Switch the game language to Japanese on startup");
            AddFontFallback = Config.Bind("General", "AddFontFallback", true, "Add a dynamic Japanese fallback font for TextMeshPro");
            TranslateHardcoded = Config.Bind("General", "TranslateHardcodedText", true, "Rewrite hardcoded strings (IL + baked TMP text)");

            Harmony.CreateAndPatchAll(typeof(AssetsPatch), "earthx2.japanese.localization");

            if (TranslateHardcoded.Value)
            {
                try { StringPatch.Apply(); }
                catch (Exception e) { Log.LogError("StringPatch init failed: " + e); }
                try { TextSweep.Apply(); }
                catch (Exception e) { Log.LogError("TextSweep init failed: " + e); }
            }

            Log.LogInfo("EarthX 2 Japanese plugin loaded; hooking AssetsManager.PrepareAssets");
        }

        private void Update()
        {
            if (_sweepFrames > 0)
            {
                _sweepFrames--;
                if ((_sweepFrames & 7) == 0) TextSweep.SweepAll();
            }
        }

        internal static void ScheduleSweep(int frames)
        {
            _sweepFrames = Math.Max(_sweepFrames, frames);
        }
    }

    [HarmonyPatch]
    internal static class AssetsPatch
    {
        private static bool _done;

        [HarmonyPatch(typeof(AssetsManager), "PrepareAssets")]
        [HarmonyPostfix]
        static void AfterPrepareAssets()
        {
            if (_done) return;
            _done = true;
            try
            {
                if (JapanesePlugin.AddFontFallback.Value) FontFix.Apply();
                if (JapanesePlugin.ForceJapanese.Value) JapaneseLanguage.Register();
                JapanesePlugin.ScheduleSweep(64);
            }
            catch (Exception e)
            {
                JapanesePlugin.Log.LogError("Patch failed: " + e);
            }
        }
    }

    internal static class FontFix
    {
        // Embedded OFL-licensed fonts shipped next to the plugin (fonts\SourceHanSansJP-*).
        // Preferred over system fonts so the patch is self-contained and copyright-safe.
        private static readonly string[] EmbeddedFonts = new string[]
        {
            "SourceHanSansJP-Regular.otf",
            "SourceHanSansJP-Bold.otf"
        };

        private static readonly string[] SystemFontFiles = new string[]
        {
            @"C:\Windows\Fonts\msjh.ttc",
            @"C:\Windows\Fonts\msjhbd.ttc",
            @"C:\Windows\Fonts\YuGothR.ttc",
            @"C:\Windows\Fonts\YuGothB.ttc",
            @"C:\Windows\Fonts\meiryo.ttc",
            @"C:\Windows\Fonts\meiryob.ttc",
            @"C:\Windows\Fonts\msgothic.ttc",
            @"C:\Windows\Fonts\SourceHanSansJ-Regular.otf",
            @"C:\Windows\Fonts\NotoSansCJKjp-Regular.otf"
        };

        public static void Apply()
        {
            try
            {
                if (TMP_Settings.fallbackFontAssets == null)
                {
                    JapanesePlugin.Log.LogWarning("TMP fallback list is null; cannot register font");
                    return;
                }

                List<TMP_FontAsset> fb = TMP_Settings.fallbackFontAssets;
                for (int i = 0; i < fb.Count; i++)
                {
                    TMP_FontAsset existing = fb[i];
                    if (existing != null &&
                        (existing.name == "ChineseFallback" || existing.name == "ChineseFallbackBold"))
                    {
                        JapanesePlugin.Log.LogInfo("Japanese fallback font already registered");
                        return;
                    }
                }

                string pluginDir = Path.GetDirectoryName(typeof(JapanesePlugin).Assembly.Location);
                TMP_FontAsset def = TMP_Settings.defaultFontAsset;

                // Embedded fonts first (both weights), then system fonts as fallback.
                bool any = false;
                string[] embedded = new string[]
                {
                    Path.Combine(pluginDir, "fonts", EmbeddedFonts[0]),
                    Path.Combine(pluginDir, "fonts", EmbeddedFonts[1])
                };
                for (int i = 0; i < embedded.Length; i++)
                {
                    TMP_FontAsset fa = LoadFontAsset(embedded[i], i == 0 ? "ChineseFallback" : "ChineseFallbackBold", def);
                    if (fa != null)
                    {
                        TMP_Settings.fallbackFontAssets.Add(fa);
                        any = true;
                    }
                }
                if (any)
                {
                    JapanesePlugin.Log.LogInfo("Japanese fallback fonts registered from plugin fonts\\ (embedded OFL)");
                    return;
                }

                for (int i = 0; i < SystemFontFiles.Length; i++)
                {
                    TMP_FontAsset fa = LoadFontAsset(SystemFontFiles[i], "ChineseFallback", def);
                    if (fa != null)
                    {
                        TMP_Settings.fallbackFontAssets.Add(fa);
                        JapanesePlugin.Log.LogInfo("Japanese fallback font registered from: " + SystemFontFiles[i]);
                        return;
                    }
                }

                JapanesePlugin.Log.LogWarning("No CJK font could be loaded; Japanese text will not render");
            }
            catch (Exception e)
            {
                JapanesePlugin.Log.LogError("FontFix failed: " + e);
            }
        }

        private static TMP_FontAsset LoadFontAsset(string path, string name, TMP_FontAsset def)
        {
            if (!File.Exists(path)) return null;
            try
            {
                Font f = CreateFontFromPath(path);
                if (f == null)
                {
                    JapanesePlugin.Log.LogWarning("Could not create Font from path: " + path);
                    return null;
                }

                TMP_FontAsset created = TMP_FontAsset.CreateFontAsset(f);
                if (created == null)
                {
                    JapanesePlugin.Log.LogWarning("CreateFontAsset failed for " + path);
                    return null;
                }

                bool ok = false;
                try { ok = created.TryAddCharacters("中文测试EarthX2", false); }
                catch (Exception e2) { JapanesePlugin.Log.LogWarning("TryAddCharacters threw for " + path + ": " + e2.Message); }
                if (!ok)
                {
                    JapanesePlugin.Log.LogWarning("Glyph rasterization test failed for " + path);
                    UnityEngine.Object.Destroy(created);
                    return null;
                }

                created.name = name;
                if (def != null && def.material != null && created.material != null)
                {
                    created.material.shader = def.material.shader;
                }
                return created;
            }
            catch (Exception e)
            {
                JapanesePlugin.Log.LogWarning("Font load failed for " + path + ": " + e.Message);
                return null;
            }
        }

        private static Font CreateFontFromPath(string path)
        {
            Font f = new Font();
            MethodInfo mi = typeof(Font).GetMethod("Internal_CreateFontFromPath",
                BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);
            if (mi == null)
            {
                JapanesePlugin.Log.LogWarning("Font.Internal_CreateFontFromPath not found");
                return null;
            }
            mi.Invoke(null, new object[] { f, path });
            return f;
        }
    }

    internal static class JapaneseLanguage
    {
        public static void Register()
        {
            try
            {
                LocalizationAsset asset = ScriptableObject.CreateInstance<LocalizationAsset>();
                asset.name = "Japanese";
                asset.Id = "Japanese";
                asset.InitializeAsset();

                int count = 0;
                if (asset.Keys != null) count = asset.Keys.Count;

                AssetsManager.Assets["Japanese"] = asset;

                try
                {
                    PropertyInfo prop = typeof(Asset).GetProperty("AssetSingleCache",
                        BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);
                    if (prop != null)
                    {
                        Dictionary<string, Asset> dict = prop.GetValue(null, null) as Dictionary<string, Asset>;
                        if (dict != null) dict["Japanese"] = asset;
                    }
                }
                catch (Exception e2)
                {
                    JapanesePlugin.Log.LogWarning("Cache prefill failed (non-fatal): " + e2.Message);
                }

                Settings.Langauge = "Japanese";
                JapanesePlugin.Log.LogInfo("Japanese language registered with " + count + " keys; Settings.Langauge=Japanese");
            }
            catch (Exception e)
            {
                JapanesePlugin.Log.LogError("Japanese language registration failed: " + e);
            }
        }
    }

    // ---------------------------------------------------------------------
    // StringPatch: rewrite hardcoded ldstr strings at JIT time
    // ---------------------------------------------------------------------
    internal static class StringPatch
    {
        private class Rule
        {
            public string[] Scopes;
            public string Translation;
        }

        private static Dictionary<string, List<Rule>> _rules = new Dictionary<string, List<Rule>>(StringComparer.Ordinal);
        private static Harmony _harmony;

        public static void Apply()
        {
            string dir = Path.GetDirectoryName(typeof(JapanesePlugin).Assembly.Location);
            LoadRules(dir);
            if (_rules.Count == 0)
            {
                JapanesePlugin.Log.LogWarning("StringPatch: no rules loaded from ja-strings*.tsv");
                return;
            }

            _harmony = new Harmony("earthx2.japanese.ilstrings");

            Assembly asm = typeof(AssetsManager).Assembly;
            string dllPath = asm.Location;

            // 1) Scan with Mono.Cecil to find methods whose body contains a target ldstr
            var targets = new HashSet<string>();
            try
            {
                var resolver = new Mono.Cecil.DefaultAssemblyResolver();
                resolver.AddSearchDirectory(Path.GetDirectoryName(dllPath));
                var rp = new Mono.Cecil.ReaderParameters();
                rp.AssemblyResolver = resolver;
                var ad = Mono.Cecil.AssemblyDefinition.ReadAssembly(dllPath, rp);

                foreach (Mono.Cecil.ModuleDefinition mod in ad.Modules)
                {
                    foreach (Mono.Cecil.TypeDefinition t in mod.GetTypes())
                    {
                        foreach (Mono.Cecil.MethodDefinition m in t.Methods)
                        {
                            if (!m.HasBody) continue;
                            string key = t.FullName + "::" + m.Name;
                            foreach (Mono.Cecil.Cil.Instruction ins in m.Body.Instructions)
                            {
                                if (ins.OpCode != Mono.Cecil.Cil.OpCodes.Ldstr) continue;
                                string s = ins.Operand as string;
                                if (s == null) continue;
                                List<Rule> list;
                                if (_rules.TryGetValue(s, out list))
                                {
                                    bool hit = false;
                                    foreach (Rule r in list)
                                    {
                                        foreach (string sc in r.Scopes)
                                        {
                                            if (key.StartsWith(sc, StringComparison.Ordinal)) { hit = true; break; }
                                        }
                                        if (hit) break;
                                    }
                                    if (hit)
                                    {
                                        targets.Add(t.FullName + "\t" + m.Name + "\t" + m.Parameters.Count);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
                ad.Dispose();
            }
            catch (Exception e)
            {
                JapanesePlugin.Log.LogError("StringPatch Cecil scan failed: " + e);
                return;
            }

            // 2) Patch each method via reflection
            int patched = 0;
            var transpiler = new HarmonyMethod(typeof(StringPatch).GetMethod("Transpiler",
                BindingFlags.Static | BindingFlags.NonPublic));

            Type[] types = null;
            try { types = asm.GetTypes(); }
            catch (ReflectionTypeLoadException ex) { types = ex.Types.Where(x => x != null).ToArray(); }
            var typeCache = new Dictionary<string, Type>(StringComparer.Ordinal);

            foreach (string tk in targets)
            {
                string[] parts = tk.Split('\t');
                string typeName = parts[0];
                string methodName = parts[1];
                int paramCount = int.Parse(parts[2]);

                Type type;
                if (!typeCache.TryGetValue(typeName, out type))
                {
                    type = types.FirstOrDefault(x => x.FullName == typeName.Replace('/', '+'));
                    typeCache[typeName] = type;
                }
                if (type == null) continue;

                var flags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly;
                MethodBase mb = null;
                if (methodName == ".ctor")
                {
                    mb = type.GetConstructors(flags).FirstOrDefault(c => c.GetParameters().Length == paramCount);
                }
                else
                {
                    mb = type.GetMethods(flags).FirstOrDefault(m2 => m2.Name == methodName && m2.GetParameters().Length == paramCount);
                }
                if (mb == null) continue;

                try
                {
                    _harmony.Patch(mb, transpiler: transpiler);
                    patched++;
                }
                catch (Exception e)
                {
                    JapanesePlugin.Log.LogWarning("StringPatch patch failed for " + tk + ": " + e.Message);
                }
            }

            JapanesePlugin.Log.LogInfo("StringPatch: " + targets.Count + " methods matched, " + patched + " patched");
        }

        private static void LoadRules(string dir)
        {
            foreach (string f in Directory.GetFiles(dir, "ja-strings*.tsv"))
            {
                string[] lines;
                try { lines = File.ReadAllLines(f, Encoding.UTF8); }
                catch (Exception e) { JapanesePlugin.Log.LogWarning("StringPatch read " + f + " failed: " + e.Message); continue; }
                foreach (string raw in lines)
                {
                    string line = raw.Trim();
                    if (line.Length == 0 || line.StartsWith("#")) continue;
                    string[] p = line.Split(new string[] { "^^^" }, StringSplitOptions.None);
                    if (p.Length < 3) continue;
                    string scopeField = p[0];
                    string orig = Unescape(p[1]);
                    string trans = Unescape(p[2]);
                    if (orig.Length == 0) continue;
                    string[] scopes = scopeField.Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries);
                    if (scopes.Length == 0) continue;
                    Rule r = new Rule { Scopes = scopes, Translation = trans };
                    List<Rule> list;
                    if (!_rules.TryGetValue(orig, out list))
                    {
                        list = new List<Rule>();
                        _rules[orig] = list;
                    }
                    list.Add(r);
                }
            }
            JapanesePlugin.Log.LogInfo("StringPatch: " + _rules.Count + " rules loaded");
        }

        private static string Unescape(string s)
        {
            return s.Replace("\\r", "\r").Replace("\\n", "\n");
        }

        private static IEnumerable<CodeInstruction> Transpiler(MethodBase __originalMethod, IEnumerable<CodeInstruction> instructions)
        {
            string decl = __originalMethod.DeclaringType != null ? __originalMethod.DeclaringType.FullName : "";
            string key = decl.Replace('+', '/') + "::" + __originalMethod.Name;
            foreach (CodeInstruction ci in instructions)
            {
                if (ci.opcode == System.Reflection.Emit.OpCodes.Ldstr)
                {
                    string s = ci.operand as string;
                    if (s != null)
                    {
                        List<Rule> list;
                        if (_rules.TryGetValue(s, out list))
                        {
                            foreach (Rule r in list)
                            {
                                bool match = false;
                                foreach (string sc in r.Scopes)
                                {
                                    if (key.StartsWith(sc, StringComparison.Ordinal)) { match = true; break; }
                                }
                                if (match) { ci.operand = r.Translation; break; }
                            }
                        }
                    }
                }
                yield return ci;
            }
        }
    }

    // ---------------------------------------------------------------------
    // TextSweep: rewrite baked TMP_Text strings at runtime
    // ---------------------------------------------------------------------
    internal static class TextSweep
    {
        private static Dictionary<string, string> _exact = new Dictionary<string, string>(StringComparer.Ordinal);
        private static Dictionary<string, string> _trimmed = new Dictionary<string, string>(StringComparer.Ordinal);
        private static bool _applied;

        public static void Apply()
        {
            if (_applied) return;
            _applied = true;
            string dir = Path.GetDirectoryName(typeof(JapanesePlugin).Assembly.Location);
            LoadMaps(dir);
            if (_exact.Count == 0)
            {
                JapanesePlugin.Log.LogWarning("TextSweep: no rules loaded from ja-baked*.tsv");
                return;
            }

            var harmony = new Harmony("earthx2.japanese.tmpsweep");

            // Patch text setters (base + both concrete overrides)
            PatchSetter(harmony, typeof(TMP_Text));
            PatchSetter(harmony, AccessTools.TypeByName("TMPro.TextMeshProUGUI"));
            PatchSetter(harmony, AccessTools.TypeByName("TMPro.TextMeshPro"));

            // Patch OnEnable to translate prefab/instantiated texts
            PatchOnEnable(harmony, AccessTools.TypeByName("TMPro.TextMeshProUGUI"));
            PatchOnEnable(harmony, AccessTools.TypeByName("TMPro.TextMeshPro"));

            SceneManager.sceneLoaded += OnSceneLoaded;
            JapanesePlugin.Log.LogInfo("TextSweep: " + _exact.Count + " rules loaded, hooks applied");
        }

        private static void LoadMaps(string dir)
        {
            foreach (string f in Directory.GetFiles(dir, "ja-baked*.tsv"))
            {
                string[] lines;
                try { lines = File.ReadAllLines(f, Encoding.UTF8); }
                catch (Exception e) { JapanesePlugin.Log.LogWarning("TextSweep read " + f + " failed: " + e.Message); continue; }
                foreach (string raw in lines)
                {
                    string line = raw.Trim();
                    if (line.Length == 0 || line.StartsWith("#")) continue;
                    string[] p = line.Split(new string[] { "^^^" }, StringSplitOptions.None);
                    if (p.Length < 2) continue;
                    string orig = Unescape(p[0]);
                    string trans = Unescape(p[1]);
                    if (orig.Length == 0) continue;
                    if (!_exact.ContainsKey(orig)) _exact[orig] = trans;
                    string t2 = orig.TrimEnd();
                    if (t2.Length > 0 && t2 != orig && !_trimmed.ContainsKey(t2)) _trimmed[t2] = trans;
                }
            }
        }

        private static string Unescape(string s)
        {
            return s.Replace("\\r", "\r").Replace("\\n", "\n");
        }

        private static void PatchSetter(Harmony harmony, Type t)
        {
            if (t == null) return;
            try
            {
                MethodInfo setter = t.GetProperty("text", BindingFlags.Public | BindingFlags.Instance).GetSetMethod();
                if (setter == null) return;
                harmony.Patch(setter, new HarmonyMethod(typeof(TextSweep).GetMethod("SetTextPrefix",
                    BindingFlags.Static | BindingFlags.NonPublic)));
            }
            catch (Exception e)
            {
                JapanesePlugin.Log.LogWarning("TextSweep setter patch failed for " + t.Name + ": " + e.Message);
            }
        }

        private static void PatchOnEnable(Harmony harmony, Type t)
        {
            if (t == null) return;
            try
            {
                MethodInfo oe = t.GetMethod("OnEnable", BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly);
                if (oe == null) return;
                harmony.Patch(oe, null, new HarmonyMethod(typeof(TextSweep).GetMethod("OnEnablePostfix",
                    BindingFlags.Static | BindingFlags.NonPublic)));
            }
            catch (Exception e)
            {
                JapanesePlugin.Log.LogWarning("TextSweep OnEnable patch failed for " + t.Name + ": " + e.Message);
            }
        }

        private static void SetTextPrefix(ref string value)
        {
            if (value == null) return;
            string t = Lookup(value);
            if (t != null) value = t;
        }

        private static void OnEnablePostfix(TMP_Text __instance)
        {
            try
            {
                if (__instance == null) return;
                string s = __instance.text;
                if (string.IsNullOrEmpty(s)) return;
                string t = Lookup(s);
                if (t != null) __instance.text = t;
            }
            catch (Exception e)
            {
                JapanesePlugin.Log.LogWarning("TextSweep OnEnable translate failed: " + e.Message);
            }
        }

        private static void OnSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            JapanesePlugin.ScheduleSweep(64);
        }

        public static void SweepAll()
        {
            try
            {
                for (int i = 0; i < SceneManager.sceneCount; i++)
                {
                    Scene sc = SceneManager.GetSceneAt(i);
                    if (!sc.isLoaded) continue;
                    GameObject[] roots = sc.GetRootGameObjects();
                    foreach (GameObject go in roots)
                    {
                        TMP_Text[] texts = go.GetComponentsInChildren<TMP_Text>(true);
                        foreach (TMP_Text tx in texts)
                        {
                            if (tx == null) continue;
                            string s = tx.text;
                            if (string.IsNullOrEmpty(s)) continue;
                            string t = Lookup(s);
                            if (t != null) tx.text = t;
                        }
                    }
                }
            }
            catch (Exception e)
            {
                JapanesePlugin.Log.LogWarning("TextSweep SweepAll failed: " + e.Message);
            }
        }

        private static string Lookup(string s)
        {
            string t;
            if (_exact.TryGetValue(s, out t)) return t;
            if (_trimmed.TryGetValue(s.TrimEnd(), out t)) return t;
            // line-level fallback (multi-line texts)
            if (s.IndexOf('\n') >= 0)
            {
                string[] lines = s.Split('\n');
                bool changed = false;
                for (int i = 0; i < lines.Length; i++)
                {
                    string lt;
                    if (_exact.TryGetValue(lines[i], out lt))
                    {
                        lines[i] = lt;
                        changed = true;
                    }
                }
                if (changed) return string.Join("\n", lines);
            }
            return null;
        }
    }
}
