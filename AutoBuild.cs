using UnityEditor;
using UnityEditor.Compilation;
using UnityEngine;
using System;
using System.IO;
using UnityEditor.Build.Reporting; // Add this for BuildReport
 
namespace BuildTools
{
    public static class AutoBuild 
    {
        private static bool isCompiling = false;
 
        [MenuItem("Build/iOS")]
        public static void BuildProject()
        {
            Debug.Log("Build process initiated...");
 
            // Check if scripts are currently compiling
            if (EditorApplication.isCompiling)
            {
                Debug.Log("Waiting for script compilation to complete...");
                CompilationPipeline.compilationFinished += OnCompilationFinished;
                isCompiling = true;
            }
            else
            {
                ExecuteBuild();
            }
        }
 
        private static void OnCompilationFinished(object obj)
        {
            if (isCompiling)
            {
                Debug.Log("Script compilation completed.");
                CompilationPipeline.compilationFinished -= OnCompilationFinished;
                isCompiling = false;
                ExecuteBuild();
            }
        }
 
        private static void ExecuteBuild()
        {
            Debug.Log("Starting iOS build process...");
 
            try
            {
                // Set iOS as the build target
                if (EditorUserBuildSettings.activeBuildTarget != BuildTarget.iOS)
                {
                    Debug.Log("Switching to iOS build target...");
                    EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.iOS, BuildTarget.iOS);
                }
 
                // Apply custom settings
                ApplySettings();
 
                // Define the build output path
                string buildPath = Path.Combine(
                    Path.GetDirectoryName(Application.dataPath),
                    "Builds/iOS"
                );
 
                // Ensure the build directory exists
                Directory.CreateDirectory(buildPath);
 
                // Get all enabled scenes from build settings
                string[] scenes = GetEnabledScenes();
 
                Debug.Log($"Building to path: {buildPath}");
                Debug.Log($"Number of scenes included: {scenes.Length}");
 
                // Record start time for build duration calculation
                DateTime startTime = DateTime.Now;
 
                // Create BuildPlayerOptions
                var buildPlayerOptions = new BuildPlayerOptions
                {
                    scenes = scenes,
                    locationPathName = buildPath,
                    target = BuildTarget.iOS,
                    options = BuildOptions.None
                };
 
                // Perform the build
                BuildReport report = BuildPipeline.BuildPlayer(buildPlayerOptions);
                BuildSummary summary = report.summary;
 
                // Calculate build duration
                TimeSpan buildDuration = DateTime.Now - startTime;
 
                // Report build results
                if (summary.result == BuildResult.Succeeded)
                {
                    Debug.Log($"Build succeeded: {buildPath}");
                    Debug.Log($"Build time: {buildDuration.TotalMinutes:F2} minutes");
                    Debug.Log($"Build size: {summary.totalSize / 1024 / 1024} MB");
                    Debug.Log($"Warnings: {summary.totalWarnings}");
                }
                else
                {
                    Debug.LogError($"Build failed with {summary.totalErrors} errors");
                    foreach (var step in report.steps)
                    {
                        foreach (var message in step.messages)
                        {
                            if (message.type == LogType.Error)
                            {
                                Debug.LogError($"Build error: {message.content}");
                            }
                        }
                    }
                    EditorApplication.Exit(1);
                }
            }
            catch (Exception e)
            {
                Debug.LogError($"Build failed with exception: {e}");
                EditorApplication.Exit(1);
            }
        }
 
        private static string[] GetEnabledScenes()
        {
            var scenes = new System.Collections.Generic.List<string>();
 
            foreach (EditorBuildSettingsScene scene in EditorBuildSettings.scenes)
            {
                if (scene.enabled)
                {
                    scenes.Add(scene.path);
                    Debug.Log($"Including scene: {scene.path}");
                }
            }
 
            return scenes.ToArray();
        }
 
        private static void ApplySettings()
        {
            Debug.Log("Applying build settings...");
 
            // Example: Set player settings
            PlayerSettings.productName = "Your Game Name";
            PlayerSettings.bundleVersion = "1.0.0";
 
            // iOS specific settings
            PlayerSettings.iOS.appleEnableAutomaticSigning = true;
            PlayerSettings.iOS.targetDevice = iOSTargetDevice.iPhoneAndiPad;
 
            // Enable UniversalRPMaterialMapper if available in TriLib
            SetMaterialMapper();
        }
 
        private static void SetMaterialMapper()
        {
            Debug.Log("Configuring TriLib settings...");
 
            var type = System.Type.GetType("TriLib.TriLibSettings, TriLib");
            if (type != null)
            {
                var property = type.GetProperty("UniversalRPMaterialMapper");
                if (property != null && property.CanWrite)
                {
                    property.SetValue(null, true);
                    Debug.Log("UniversalRPMaterialMapper set to TRUE.");
                }
                else
                {
                    Debug.LogWarning("Failed to find UniversalRPMaterialMapper property.");
                }
            }
            else
            {
                Debug.LogWarning("TriLib settings class not found.");
            }
        }
    }
}
