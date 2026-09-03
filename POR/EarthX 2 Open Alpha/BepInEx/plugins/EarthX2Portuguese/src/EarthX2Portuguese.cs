// EarthX 2 Portuguese Localization Plugin v1
// - Registers a "Portuguese" LocalizationAsset backed by StreamingAssets/Localization/Portuguese
// - No font fallback needed: Portuguese (Latin script incl. á/â/ã/ç) renders with the
//   game-embedded LiberationSans SDF (see AI-PATCH-GUIDE.md §2.5)
// - StringPatch: rewrites hardcoded ldstr strings in Assembly-CSharp.dll at JIT time
//   using rules from pt-strings*.tsv (SCOPE^^^ORIG^^^TRANS)
// - TextSweep: rewrites baked TMP_Text strings at runtime using pt-baked*.tsv (ORIG^^^TRANS)
// Compiled against the game's own assemblies with .NET Framework csc (C# 5 syntax).
// Forked from EarthX2German v1.0.0 (language changes are limited to identifiers/strings).

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

namespace EarthX2Portuguese
{
    [BepInPlugin("earthx2.portuguese.localization", "EarthX 2 Portuguese Localization", "1.0.0")]
    public class PortuguesePlugin : BaseUnityPlugin
    {
        internal static ManualLogSource Log;
        internal static ConfigEntry<bool> ForcePortuguese;
        internal static ConfigEntry<bool> TranslateHardcoded;

        private static int _sweepFrames;

        private void Awake()
        {
            Log = Logger;
            ForcePortuguese = Config.Bind("General", "ForcePortuguese", true, "Switch the game language to Portuguese on startup");
            TranslateHardcoded = Config.Bind("General", "TranslateHardcodedText", true, "Rewrite hardcoded strings (IL + baked TMP text)");

            Harmony.CreateAndPatchAll(typeof(AssetsPatch), "earthx2.portuguese.localization");

            if (TranslateHardcoded.Value)
            {
                try { StringPatch.Apply(); }
                catch (Exception e) { Log.LogError("StringPatch init failed: " + e); }
                try { TextSweep.Apply(); }
                catch (Exception e) { Log.LogError("TextSweep init failed: " + e); }
            }

            Log.LogInfo("EarthX 2 Portuguese plugin loaded; hooking AssetsManager.PrepareAssets");
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
                if (PortuguesePlugin.ForcePortuguese.Value) PortugueseLanguage.Register();
                PortuguesePlugin.ScheduleSweep(64);
            }
            catch (Exception e)
            {
                PortuguesePlugin.Log.LogError("Patch failed: " + e);
            }
        }
    }

    internal static class PortugueseLanguage
    {
        public static void Register()
        {
            try
            {
                LocalizationAsset asset = ScriptableObject.CreateInstance<LocalizationAsset>();
                asset.name = "Portuguese";
                asset.Id = "Portuguese";
                asset.InitializeAsset();

                int count = 0;
                if (asset.Keys != null) count = asset.Keys.Count;

                AssetsManager.Assets["Portuguese"] = asset;

                try
                {
                    PropertyInfo prop = typeof(Asset).GetProperty("AssetSingleCache",
                        BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);
                    if (prop != null)
                    {
                        Dictionary<string, Asset> dict = prop.GetValue(null, null) as Dictionary<string, Asset>;
                        if (dict != null) dict["Portuguese"] = asset;
                    }
                }
                catch (Exception e2)
                {
                    PortuguesePlugin.Log.LogWarning("Cache prefill failed (non-fatal): " + e2.Message);
                }

                Settings.Langauge = "Portuguese";
                PortuguesePlugin.Log.LogInfo("Portuguese language registered with " + count + " keys; Settings.Langauge=Portuguese");
            }
            catch (Exception e)
            {
                PortuguesePlugin.Log.LogError("Portuguese language registration failed: " + e);
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
            string dir = Path.GetDirectoryName(typeof(PortuguesePlugin).Assembly.Location);
            LoadRules(dir);
            if (_rules.Count == 0)
            {
                PortuguesePlugin.Log.LogWarning("StringPatch: no rules loaded from pt-strings*.tsv");
                return;
            }

            _harmony = new Harmony("earthx2.portuguese.ilstrings");

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
                PortuguesePlugin.Log.LogError("StringPatch Cecil scan failed: " + e);
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
                    PortuguesePlugin.Log.LogWarning("StringPatch patch failed for " + tk + ": " + e.Message);
                }
            }

            PortuguesePlugin.Log.LogInfo("StringPatch: " + targets.Count + " methods matched, " + patched + " patched");
        }

        private static void LoadRules(string dir)
        {
            foreach (string f in Directory.GetFiles(dir, "pt-strings*.tsv"))
            {
                string[] lines;
                try { lines = File.ReadAllLines(f, Encoding.UTF8); }
                catch (Exception e) { PortuguesePlugin.Log.LogWarning("StringPatch read " + f + " failed: " + e.Message); continue; }
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
            PortuguesePlugin.Log.LogInfo("StringPatch: " + _rules.Count + " rules loaded");
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
            string dir = Path.GetDirectoryName(typeof(PortuguesePlugin).Assembly.Location);
            LoadMaps(dir);
            if (_exact.Count == 0)
            {
                PortuguesePlugin.Log.LogWarning("TextSweep: no rules loaded from pt-baked*.tsv");
                return;
            }

            var harmony = new Harmony("earthx2.portuguese.tmpsweep");

            // Patch text setters (base + both concrete overrides)
            PatchSetter(harmony, typeof(TMP_Text));
            PatchSetter(harmony, AccessTools.TypeByName("TMPro.TextMeshProUGUI"));
            PatchSetter(harmony, AccessTools.TypeByName("TMPro.TextMeshPro"));

            // Patch OnEnable to translate prefab/instantiated texts
            PatchOnEnable(harmony, AccessTools.TypeByName("TMPro.TextMeshProUGUI"));
            PatchOnEnable(harmony, AccessTools.TypeByName("TMPro.TextMeshPro"));

            SceneManager.sceneLoaded += OnSceneLoaded;
            PortuguesePlugin.Log.LogInfo("TextSweep: " + _exact.Count + " rules loaded, hooks applied");
        }

        private static void LoadMaps(string dir)
        {
            foreach (string f in Directory.GetFiles(dir, "pt-baked*.tsv"))
            {
                string[] lines;
                try { lines = File.ReadAllLines(f, Encoding.UTF8); }
                catch (Exception e) { PortuguesePlugin.Log.LogWarning("TextSweep read " + f + " failed: " + e.Message); continue; }
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
                PortuguesePlugin.Log.LogWarning("TextSweep setter patch failed for " + t.Name + ": " + e.Message);
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
                PortuguesePlugin.Log.LogWarning("TextSweep OnEnable patch failed for " + t.Name + ": " + e.Message);
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
                PortuguesePlugin.Log.LogWarning("TextSweep OnEnable translate failed: " + e.Message);
            }
        }

        private static void OnSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            PortuguesePlugin.ScheduleSweep(64);
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
                PortuguesePlugin.Log.LogWarning("TextSweep SweepAll failed: " + e.Message);
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
