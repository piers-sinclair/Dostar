using System.Diagnostics;
using System.Text.RegularExpressions;

namespace Dostar.Cli.Commands;

internal static class NewProjectCommand
{
    private static readonly Regex PascalCaseRegex = new(@"^[A-Z][a-zA-Z0-9]*$", RegexOptions.Compiled);

    private static readonly string[] TextExtensions =
    [
        ".cs", ".csproj", ".slnx", ".sln", ".json", ".xml", ".config", ".yaml", ".yml",
        ".md", ".txt", ".sh", ".ps1", ".ts", ".tsx", ".js", ".jsx", ".html", ".css",
        ".scss", ".env", ".gitignore", ".gitattributes", ".editorconfig", ".props",
        ".targets", ".bicep", ".http", ".razor", ".cshtml", ".toml"
    ];

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

        var repoOption = new Option<string>("--repo")
        {
            Description = "Git repository URL to clone from",
            DefaultValueFactory = _ => "https://github.com/piers-sinclair/Dostar.git"
        };

        var command = new Command("new-project", "Bootstrap a new project from the Dostar template");
        command.Arguments.Add(nameArg);
        command.Options.Add(outputOption);
        command.Options.Add(repoOption);

        command.SetAction(async (parseResult, _) =>
        {
            var name = parseResult.GetValue(nameArg)!;
            var output = parseResult.GetValue(outputOption);
            var repo = parseResult.GetValue(repoOption)!;
            return await HandleAsync(name, output, repo);
        });

        return command;
    }

    private static async Task<int> HandleAsync(string projectName, string? output, string repoUrl)
    {
        if (!PascalCaseRegex.IsMatch(projectName))
        {
            Console.Error.WriteLine($"Error: Project name '{projectName}' is not valid PascalCase.");
            Console.Error.WriteLine("The name must start with an uppercase letter and contain only letters and digits.");
            Console.Error.WriteLine("Examples: MyStartup, AcmeCorp, ProjectAlpha");
            return 1;
        }

        var outputDir = output ?? Path.Combine(Directory.GetCurrentDirectory(), projectName);
        outputDir = Path.GetFullPath(outputDir);

        if (Directory.Exists(outputDir) && Directory.EnumerateFileSystemEntries(outputDir).Any())
        {
            Console.Error.WriteLine($"Error: Output directory '{outputDir}' already exists and is not empty.");
            return 1;
        }

        Console.WriteLine($"Creating new project '{projectName}' in '{outputDir}'...");
        Console.WriteLine();

        // Step 1: Clone the repo
        Console.WriteLine($"Cloning template from {repoUrl}...");
        var cloneResult = await RunProcessAsync("git", ["clone", repoUrl, outputDir], Directory.GetCurrentDirectory());
        if (cloneResult != 0)
        {
            Console.Error.WriteLine("Error: git clone failed.");
            return 1;
        }

        // Step 2: Remove .git directory
        Console.WriteLine("Removing template git history...");
        var gitDir = Path.Combine(outputDir, ".git");
        if (Directory.Exists(gitDir))
            DeleteDirectoryForce(gitDir);

        // Step 3: Rename files and directories + replace contents
        Console.WriteLine("Renaming Dostar references...");
        var projectNameLower = projectName.ToLowerInvariant();

        // Rename file/directory names (bottom-up so we rename children before parents)
        RenameFileSystemEntries(outputDir, projectName, projectNameLower);

        // Replace file contents
        ReplaceFileContents(outputDir, projectName, projectNameLower);

        Console.WriteLine("Renaming complete.");

        // Step 4: git init
        Console.WriteLine("Initialising fresh git repository...");
        var gitInitResult = await RunProcessAsync("git", ["init"], outputDir);
        if (gitInitResult != 0)
        {
            Console.Error.WriteLine("Warning: 'git init' failed. You can run it manually.");
        }

        // Step 5: Print success message
        Console.WriteLine();
        Console.WriteLine($"Project '{projectName}' created successfully at '{outputDir}'.");
        Console.WriteLine();
        Console.WriteLine("Next steps:");
        Console.WriteLine($"  cd {projectName}");
        Console.WriteLine("  dotnet build");
        Console.WriteLine("  cd frontend && pnpm dev");
        return 0;
    }

    private static void RenameFileSystemEntries(string rootDir, string projectName, string projectNameLower)
    {
        // Process bottom-up: enumerate all entries depth-first, process deepest first
        RenameEntriesRecursive(new DirectoryInfo(rootDir), projectName, projectNameLower);
    }

    private static void RenameEntriesRecursive(DirectoryInfo dir, string projectName, string projectNameLower)
    {
        foreach (var subDir in dir.GetDirectories())
        {
            if (subDir.Name == ".git")
                continue;

            RenameEntriesRecursive(subDir, projectName, projectNameLower);

            // Rename the directory itself if it contains "Dostar" or "dostar"
            var newName = ApplyNameSubstitution(subDir.Name, projectName, projectNameLower);
            if (newName != subDir.Name)
            {
                var newPath = Path.Combine(subDir.Parent!.FullName, newName);
                subDir.MoveTo(newPath);
            }
        }

        foreach (var file in dir.GetFiles())
        {
            var newName = ApplyNameSubstitution(file.Name, projectName, projectNameLower);
            if (newName != file.Name)
            {
                var newPath = Path.Combine(file.DirectoryName!, newName);
                file.MoveTo(newPath);
            }
        }
    }

    private static void ReplaceFileContents(string rootDir, string projectName, string projectNameLower)
    {
        foreach (var filePath in Directory.EnumerateFiles(rootDir, "*", SearchOption.AllDirectories))
        {
            // Skip .git directories
            var relativePath = Path.GetRelativePath(rootDir, filePath);
            if (relativePath.StartsWith(".git" + Path.DirectorySeparatorChar, StringComparison.Ordinal) ||
                relativePath == ".git")
                continue;

            if (!IsTextFile(filePath))
                continue;

            try
            {
                var content = File.ReadAllText(filePath);
                var newContent = ApplyNameSubstitution(content, projectName, projectNameLower);
                if (newContent != content)
                    File.WriteAllText(filePath, newContent);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Warning: Could not process '{filePath}': {ex.Message}");
            }
        }
    }

    private static string ApplyNameSubstitution(string input, string projectName, string projectNameLower)
    {
        // Replace "Dostar" (PascalCase) with <ProjectName>
        // Replace "dostar" (lowercase) with lowercase of <ProjectName>
        return input
            .Replace("Dostar", projectName, StringComparison.Ordinal)
            .Replace("dostar", projectNameLower, StringComparison.Ordinal);
    }

    private static bool IsTextFile(string filePath)
    {
        var ext = Path.GetExtension(filePath).ToLowerInvariant();
        if (TextExtensions.Contains(ext))
            return true;

        // Files with no extension may be text (e.g. Dockerfile, Makefile)
        if (string.IsNullOrEmpty(ext))
        {
            var fileName = Path.GetFileName(filePath);
            return fileName is "Dockerfile" or "Makefile" or "LICENSE" or "NOTICE" or "AUTHORS";
        }

        return false;
    }

    private static void DeleteDirectoryForce(string path)
    {
        // On Windows, .git files may be read-only — clear the attribute before deleting
        foreach (var file in Directory.EnumerateFiles(path, "*", SearchOption.AllDirectories))
        {
            var attrs = File.GetAttributes(file);
            if ((attrs & FileAttributes.ReadOnly) != 0)
                File.SetAttributes(file, attrs & ~FileAttributes.ReadOnly);
        }

        Directory.Delete(path, recursive: true);
    }

    private static async Task<int> RunProcessAsync(string fileName, IEnumerable<string> args, string workingDirectory)
    {
        using var process = new Process();
        process.StartInfo = new ProcessStartInfo
        {
            FileName = fileName,
            WorkingDirectory = workingDirectory,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };

        foreach (var arg in args)
            process.StartInfo.ArgumentList.Add(arg);

        process.OutputDataReceived += (_, e) =>
        {
            if (e.Data is not null)
                Console.WriteLine(e.Data);
        };
        process.ErrorDataReceived += (_, e) =>
        {
            if (e.Data is not null)
                Console.Error.WriteLine(e.Data);
        };

        process.Start();
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();

        await process.WaitForExitAsync();
        return process.ExitCode;
    }
}
