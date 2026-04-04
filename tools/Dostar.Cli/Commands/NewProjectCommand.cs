using System.Diagnostics;
using System.Text.RegularExpressions;

namespace Dostar.Cli.Commands;

internal static class NewProjectCommand
{
    private const string TemplateRepoUrl = "https://github.com/piers-sinclair/Dostar.git";

    private static readonly Regex PascalCaseRegex = new(@"^[A-Z][a-zA-Z0-9]*$", RegexOptions.Compiled);

    internal static Command Build()
    {
        var nameArg = new Argument<string>("ProjectName")
        {
            Description = "PascalCase name for the new project (e.g. MyStartup)"
        };

        var outputOption = new Option<string?>("--output")
        {
            Description = "Destination directory (defaults to ./<ProjectName>)"
        };
        outputOption.Aliases.Add("-o");

        var command = new Command("new-project", "Bootstrap a new project from the Dostar template");
        command.Arguments.Add(nameArg);
        command.Options.Add(outputOption);

        command.SetAction((parseResult, _) => HandleAsync(
            parseResult.GetValue(nameArg)!,
            parseResult.GetValue(outputOption)));

        return command;
    }

    private static async Task<int> HandleAsync(string projectName, string? output)
    {
        if (!PascalCaseRegex.IsMatch(projectName))
        {
            Console.Error.WriteLine($"Error: Project name '{projectName}' is not valid PascalCase.");
            Console.Error.WriteLine("The name must start with an uppercase letter and contain only letters and digits.");
            Console.Error.WriteLine("Examples: MyStartup, AcmeCorp, ProjectAlpha");
            return 1;
        }

        var outputDir = Path.GetFullPath(output ?? Path.Combine(Directory.GetCurrentDirectory(), projectName));

        if (Directory.Exists(outputDir) && Directory.EnumerateFileSystemEntries(outputDir).Any())
        {
            Console.Error.WriteLine($"Error: Output directory '{outputDir}' already exists and is not empty.");
            return 1;
        }

        Console.WriteLine($"Creating new project '{projectName}' in '{outputDir}'...");
        Console.WriteLine();

        if (!await CloneDostarAsync(outputDir))
            return 1;

        RemoveGitHistory(outputDir);

        Console.WriteLine("Renaming Dostar references...");
        TemplateRenamer.Apply(outputDir, projectName);
        Console.WriteLine("Renaming complete.");

        PrintSuccessMessage(projectName, outputDir);
        return 0;
    }

    private static async Task<bool> CloneDostarAsync(string outputDir)
    {
        Console.WriteLine("Cloning Dostar template...");

        using var process = new Process();
        process.StartInfo = new ProcessStartInfo
        {
            FileName = "git",
            WorkingDirectory = Directory.GetCurrentDirectory(),
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };
        process.StartInfo.ArgumentList.Add("clone");
        process.StartInfo.ArgumentList.Add(TemplateRepoUrl);
        process.StartInfo.ArgumentList.Add(outputDir);
        process.OutputDataReceived += (_, e) => { if (e.Data is not null) Console.WriteLine(e.Data); };
        process.ErrorDataReceived += (_, e) => { if (e.Data is not null) Console.Error.WriteLine(e.Data); };

        process.Start();
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();
        await process.WaitForExitAsync();

        if (process.ExitCode != 0)
            Console.Error.WriteLine("Error: git clone failed.");

        return process.ExitCode == 0;
    }

    private static void RemoveGitHistory(string outputDir)
    {
        Console.WriteLine("Removing template git history...");
        var gitDir = Path.Combine(outputDir, ".git");
        if (Directory.Exists(gitDir))
            DeleteDirectoryForce(gitDir);
    }

    private static void PrintSuccessMessage(string projectName, string outputDir)
    {
        Console.WriteLine();
        Console.WriteLine($"Project '{projectName}' created successfully at '{outputDir}'.");
        Console.WriteLine();
        Console.WriteLine("Next steps:");
        Console.WriteLine($"  cd {projectName}");
        Console.WriteLine("  git init && git add . && git commit -m \"Initial commit\"");
        Console.WriteLine("  dotnet build");
        Console.WriteLine("  cd frontend && pnpm dev");
    }

    private static void DeleteDirectoryForce(string path)
    {
        foreach (var file in Directory.EnumerateFiles(path, "*", SearchOption.AllDirectories))
        {
            var attrs = File.GetAttributes(file);
            if ((attrs & FileAttributes.ReadOnly) != 0)
                File.SetAttributes(file, attrs & ~FileAttributes.ReadOnly);
        }

        Directory.Delete(path, recursive: true);
    }
}