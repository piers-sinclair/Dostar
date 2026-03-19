namespace Dostar.Cli.Commands;

internal static class RemoveModuleCommand
{
    internal static Command Build()
    {
        var nameArg = new Argument<string>("name")
        {
            Description = "The name of the module to remove (e.g. Billing)"
        };
        var dryRunOption = new Option<bool>("--dry-run")
        {
            Description = "Print what would be deleted without making any changes"
        };
        var yesOption = new Option<bool>("--yes")
        {
            Description = "Skip confirmation prompt"
        };
        yesOption.Aliases.Add("-y");

        var command = new Command("remove-module", "Remove a module and all associated projects from the solution");
        command.Arguments.Add(nameArg);
        command.Options.Add(dryRunOption);
        command.Options.Add(yesOption);

        command.SetAction(async (parseResult, _) =>
        {
            var name = parseResult.GetValue(nameArg)!;
            var dryRun = parseResult.GetValue(dryRunOption);
            var yes = parseResult.GetValue(yesOption);
            return await HandleAsync(name, dryRun, yes);
        });

        return command;
    }

    private static async Task<int> HandleAsync(string name, bool dryRun, bool yes)
    {
        var repoRoot = FindRepoRoot();
        if (repoRoot is null)
        {
            Console.Error.WriteLine("Error: could not find repo root (no Dostar.slnx found).");
            return 1;
        }

        var moduleDir = Path.Combine(repoRoot, "backend", "Modules", name);
        if (!Directory.Exists(moduleDir))
        {
            Console.Error.WriteLine($"Error: module '{name}' does not exist at {moduleDir}");
            return 1;
        }

        var slnxPath = Path.Combine(repoRoot, "Dostar.slnx");
        var programCsPath = Path.Combine(repoRoot, "backend", "Dostar.Api", "Program.cs");
        var apiCsproj = Path.Combine(repoRoot, "backend", "Dostar.Api", "Dostar.Api.csproj");

        var projectPaths = new[]
        {
            Path.Combine(moduleDir, $"Dostar.{name}.Contracts", $"Dostar.{name}.Contracts.csproj"),
            Path.Combine(moduleDir, $"Dostar.{name}.Implementation", $"Dostar.{name}.Implementation.csproj"),
            Path.Combine(moduleDir, $"Dostar.{name}.UnitTests", $"Dostar.{name}.UnitTests.csproj"),
            Path.Combine(moduleDir, $"Dostar.{name}.IntegrationTests", $"Dostar.{name}.IntegrationTests.csproj"),
        };

        // Check for cross-references from other modules
        WarnIfCrossReferences(repoRoot, name);

        // Show plan
        Console.WriteLine(dryRun ? "[DRY RUN] The following changes would be made:" : "The following changes will be made:");
        Console.WriteLine();
        Console.WriteLine($"  Remove directory:              {moduleDir}");
        foreach (var proj in projectPaths)
            Console.WriteLine($"  Remove from solution:          {Path.GetRelativePath(repoRoot, proj)}");
        Console.WriteLine($"  Remove project reference:      Dostar.Api -> Dostar.{name}.Implementation");
        Console.WriteLine($"  Remove module registration:    new {name}Module() from {Path.GetRelativePath(repoRoot, programCsPath)}");
        Console.WriteLine();

        if (dryRun)
        {
            Console.WriteLine("Dry run complete. No changes were made.");
            return 0;
        }

        if (!yes)
        {
            Console.Write($"Remove module {name}? [y/N] ");
            var response = Console.ReadLine()?.Trim().ToLowerInvariant();
            if (response != "y" && response != "yes")
            {
                Console.WriteLine("Aborted.");
                return 0;
            }
        }

        // Remove project reference from Dostar.Api
        var implCsproj = Path.Combine(moduleDir, $"Dostar.{name}.Implementation", $"Dostar.{name}.Implementation.csproj");
        await RunProcessAsync(repoRoot, "dotnet", "remove", apiCsproj, "reference", implCsproj);

        // Remove all projects from the solution
        foreach (var proj in projectPaths)
        {
            if (!File.Exists(proj))
            {
                Console.WriteLine($"  Skipping (not found): {Path.GetRelativePath(repoRoot, proj)}");
                continue;
            }

            await RunProcessAsync(repoRoot, "dotnet", "sln", slnxPath, "remove", proj);
        }

        // Remove new <Name>Module() from Program.cs
        RemoveModuleRegistration(programCsPath, name);

        // Delete module directory
        Directory.Delete(moduleDir, recursive: true);
        Console.WriteLine($"Deleted: {moduleDir}");

        Console.WriteLine();
        Console.WriteLine($"Module '{name}' removed successfully.");
        return 0;
    }

    private static void WarnIfCrossReferences(string repoRoot, string name)
    {
        var contractsRef = $"Dostar.{name}.Contracts";
        var modulesDir = Path.Combine(repoRoot, "backend", "Modules");
        if (!Directory.Exists(modulesDir))
            return;

        var referencingProjects = new List<string>();
        foreach (var csproj in Directory.EnumerateFiles(modulesDir, "*.csproj", SearchOption.AllDirectories))
        {
            // Skip the module's own projects
            if (csproj.Contains(Path.Combine("Modules", name) + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
                continue;

            var content = File.ReadAllText(csproj);
            if (content.Contains(contractsRef, StringComparison.OrdinalIgnoreCase))
                referencingProjects.Add(Path.GetFileName(csproj));
        }

        if (referencingProjects.Count > 0)
        {
            Console.WriteLine($"Warning: the following projects reference Dostar.{name}.Contracts:");
            foreach (var proj in referencingProjects)
                Console.WriteLine($"  {proj}");
            Console.WriteLine("These references will become broken after removal.");
            Console.WriteLine();
        }
    }

    private static void RemoveModuleRegistration(string programCsPath, string name)
    {
        if (!File.Exists(programCsPath))
        {
            Console.Error.WriteLine($"Warning: Program.cs not found at {programCsPath}");
            return;
        }

        var content = File.ReadAllText(programCsPath);
        var moduleRegistration = $"new {name}Module()";

        if (!content.Contains(moduleRegistration, StringComparison.Ordinal))
        {
            Console.WriteLine($"Warning: could not find '{moduleRegistration}' in Program.cs — skipped.");
            return;
        }

        // Remove the line containing the module registration
        var lines = content.Split('\n').ToList();
        for (var i = lines.Count - 1; i >= 0; i--)
        {
            if (!lines[i].Contains(moduleRegistration, StringComparison.Ordinal))
                continue;

            lines.RemoveAt(i);
            break;
        }

        // Also remove the using statement for this module's implementation namespace
        var usingStatement = $"using Dostar.{name}.Implementation;";
        for (var i = lines.Count - 1; i >= 0; i--)
        {
            if (!lines[i].Contains(usingStatement, StringComparison.Ordinal))
                continue;

            lines.RemoveAt(i);
            break;
        }

        File.WriteAllText(programCsPath, string.Join('\n', lines));
        Console.WriteLine($"Removed 'new {name}Module()' registration from Program.cs");
    }

    private static string? FindRepoRoot()
    {
        var dir = new DirectoryInfo(Directory.GetCurrentDirectory());
        while (dir is not null)
        {
            if (File.Exists(Path.Combine(dir.FullName, "Dostar.slnx")))
                return dir.FullName;
            dir = dir.Parent;
        }

        return null;
    }

    private static async Task RunProcessAsync(string workingDir, string fileName, params string[] args)
    {
        using var process = new System.Diagnostics.Process();
        process.StartInfo = new System.Diagnostics.ProcessStartInfo
        {
            FileName = fileName,
            WorkingDirectory = workingDir,
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

        if (process.ExitCode != 0)
            Console.Error.WriteLine($"Warning: '{fileName} {string.Join(" ", args)}' exited with code {process.ExitCode}.");
    }
}
