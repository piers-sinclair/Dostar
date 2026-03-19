using System.Reflection;
using System.Text.RegularExpressions;
using Scriban;

namespace Dostar.Cli.Commands;

internal static class AddModuleCommand
{
    private static readonly Regex PascalCaseRegex = new(@"^[A-Z][a-zA-Z0-9]*$", RegexOptions.Compiled);

    internal static Command Build()
    {
        var nameArg = new Argument<string>("name")
        {
            Description = "PascalCase name for the new module (e.g. Billing)"
        };

        var command = new Command("add-module", "Scaffold a new feature module with Contracts, Implementation, UnitTests, and IntegrationTests projects");
        command.Arguments.Add(nameArg);

        command.SetAction(async (parseResult, _) =>
        {
            var name = parseResult.GetValue(nameArg)!;
            return await HandleAsync(name);
        });

        return command;
    }

    private static async Task<int> HandleAsync(string name)
    {
        if (!PascalCaseRegex.IsMatch(name))
        {
            Console.Error.WriteLine($"Error: Module name '{name}' is not valid PascalCase.");
            Console.Error.WriteLine("The name must start with an uppercase letter and contain only letters and digits.");
            Console.Error.WriteLine("Examples: Billing, UserManagement, OrderProcessing");
            return 1;
        }

        var repoRoot = FindRepoRoot();
        if (repoRoot is null)
        {
            Console.Error.WriteLine("Error: could not find repo root (no Dostar.slnx found).");
            return 1;
        }

        var modulesDir = Path.Combine(repoRoot, "backend", "Modules", name);

        if (Directory.Exists(modulesDir))
        {
            Console.WriteLine($"Module '{name}' already exists at {modulesDir}. Nothing to do.");
            return 0;
        }

        Console.WriteLine($"Scaffolding module '{name}'...");

        var model = new { name };

        // Create directory structure
        var contractsDir = Path.Combine(modulesDir, $"Dostar.{name}.Contracts");
        var implDir = Path.Combine(modulesDir, $"Dostar.{name}.Implementation");
        var unitTestsDir = Path.Combine(modulesDir, $"Dostar.{name}.UnitTests");
        var integrationTestsDir = Path.Combine(modulesDir, $"Dostar.{name}.IntegrationTests");

        Directory.CreateDirectory(contractsDir);
        Directory.CreateDirectory(implDir);
        Directory.CreateDirectory(unitTestsDir);
        Directory.CreateDirectory(integrationTestsDir);

        // Generate files from templates
        await RenderTemplateAsync("Contracts.csproj.scriban", model,
            Path.Combine(contractsDir, $"Dostar.{name}.Contracts.csproj"));

        await RenderTemplateAsync("Implementation.csproj.scriban", model,
            Path.Combine(implDir, $"Dostar.{name}.Implementation.csproj"));

        await RenderTemplateAsync("Module.cs.scriban", model,
            Path.Combine(implDir, $"{name}Module.cs"));

        await RenderTemplateAsync("ImplementationGlobalUsings.cs.scriban", model,
            Path.Combine(implDir, "GlobalUsings.cs"));

        await RenderTemplateAsync("UnitTests.csproj.scriban", model,
            Path.Combine(unitTestsDir, $"Dostar.{name}.UnitTests.csproj"));

        await RenderTemplateAsync("UnitTestsGlobalUsings.cs.scriban", model,
            Path.Combine(unitTestsDir, "GlobalUsings.cs"));

        await RenderTemplateAsync("UnitTestsClass.cs.scriban", model,
            Path.Combine(unitTestsDir, $"{name}ModuleTests.cs"));

        await RenderTemplateAsync("IntegrationTests.csproj.scriban", model,
            Path.Combine(integrationTestsDir, $"Dostar.{name}.IntegrationTests.csproj"));

        await RenderTemplateAsync("IntegrationTestsGlobalUsings.cs.scriban", model,
            Path.Combine(integrationTestsDir, "GlobalUsings.cs"));

        await RenderTemplateAsync("IntegrationTestsClass.cs.scriban", model,
            Path.Combine(integrationTestsDir, $"{name}ModuleIntegrationTests.cs"));

        await RenderTemplateAsync("ApiFactory.cs.scriban", model,
            Path.Combine(integrationTestsDir, "ApiFactory.cs"));

        Console.WriteLine("  Generated project files.");

        // Add projects to solution
        var slnxPath = Path.Combine(repoRoot, "Dostar.slnx");
        await AddProjectsToSolutionAsync(slnxPath, name, repoRoot);

        // Add project reference from Dostar.Api to Implementation
        var apiCsproj = Path.Combine(repoRoot, "backend", "Dostar.Api", "Dostar.Api.csproj");
        var implCsproj = Path.Combine(modulesDir, $"Dostar.{name}.Implementation", $"Dostar.{name}.Implementation.csproj");
        var addRefResult = await RunProcessAsync("dotnet", $"add \"{apiCsproj}\" reference \"{implCsproj}\"", repoRoot);
        if (addRefResult != 0)
            Console.Error.WriteLine($"Warning: 'dotnet add reference' exited with code {addRefResult}.");
        else
            Console.WriteLine($"  Added reference from Dostar.Api to Dostar.{name}.Implementation.");

        // Register module in Program.cs
        var programCsPath = Path.Combine(repoRoot, "backend", "Dostar.Api", "Program.cs");
        AddModuleRegistration(programCsPath, name);

        Console.WriteLine($"Module '{name}' scaffolded successfully.");
        Console.WriteLine($"  Location: {modulesDir}");
        Console.WriteLine("  Next steps:");
        Console.WriteLine("    - Run: dotnet build");
        Console.WriteLine($"    - Add EF Core migrations if needed");
        return 0;
    }

    private static async Task RenderTemplateAsync(string templateName, object model, string outputPath)
    {
        var templateContent = LoadEmbeddedTemplate(templateName);
        var template = Template.Parse(templateContent);
        var result = await template.RenderAsync(model);
        await File.WriteAllTextAsync(outputPath, result);
    }

    private static string LoadEmbeddedTemplate(string templateName)
    {
        var assembly = Assembly.GetExecutingAssembly();
        var resourceName = $"Dostar.Cli.Templates.{templateName}";

        using var stream = assembly.GetManifestResourceStream(resourceName)
            ?? throw new InvalidOperationException($"Embedded template '{resourceName}' not found.");
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }

    private static async Task AddProjectsToSolutionAsync(string slnxPath, string name, string repoRoot)
    {
        var projects = new[]
        {
            $"backend/Modules/{name}/Dostar.{name}.Contracts/Dostar.{name}.Contracts.csproj",
            $"backend/Modules/{name}/Dostar.{name}.Implementation/Dostar.{name}.Implementation.csproj",
            $"backend/Modules/{name}/Dostar.{name}.UnitTests/Dostar.{name}.UnitTests.csproj",
            $"backend/Modules/{name}/Dostar.{name}.IntegrationTests/Dostar.{name}.IntegrationTests.csproj",
        };

        foreach (var project in projects)
        {
            var result = await RunProcessAsync(
                "dotnet",
                $"sln \"{slnxPath}\" add --solution-folder \"/backend/\" \"{project}\"",
                repoRoot);

            if (result != 0)
                Console.Error.WriteLine($"Warning: 'dotnet sln add' exited with code {result} for {project}");
        }

        Console.WriteLine($"  Added {projects.Length} projects to Dostar.slnx.");
    }

    private static void AddModuleRegistration(string programCsPath, string name)
    {
        if (!File.Exists(programCsPath))
        {
            Console.Error.WriteLine($"Warning: Program.cs not found at {programCsPath}");
            return;
        }

        var content = File.ReadAllText(programCsPath);

        // Check if module already registered
        if (content.Contains($"new {name}Module()"))
        {
            Console.WriteLine($"  {name}Module already registered in Program.cs.");
            return;
        }

        // Add using statement for the new module's implementation namespace
        var usingStatement = $"using Dostar.{name}.Implementation;";
        if (!content.Contains(usingStatement))
        {
            var lastDostarUsing = content.LastIndexOf("using Dostar.", StringComparison.Ordinal);
            if (lastDostarUsing >= 0)
            {
                var endOfLine = content.IndexOf('\n', lastDostarUsing);
                content = content.Insert(endOfLine + 1, $"{usingStatement}\n");
            }
            else
            {
                content = $"{usingStatement}\n{content}";
            }
        }

        // Find the closing ]; of the modules array and insert new module before it
        var moduleArrayPattern = "IModule[] modules =\n[";
        var moduleArrayIndex = content.IndexOf(moduleArrayPattern, StringComparison.Ordinal);
        if (moduleArrayIndex < 0)
        {
            Console.Error.WriteLine("Warning: Could not find 'IModule[] modules' array in Program.cs. Please register the module manually.");
            File.WriteAllText(programCsPath, content);
            return;
        }

        var closingIndex = content.IndexOf("];", moduleArrayIndex, StringComparison.Ordinal);
        if (closingIndex < 0)
        {
            Console.Error.WriteLine("Warning: Could not find end of modules array in Program.cs. Please register the module manually.");
            File.WriteAllText(programCsPath, content);
            return;
        }

        content = content.Insert(closingIndex, $"    new {name}Module(),\n");
        File.WriteAllText(programCsPath, content);
        Console.WriteLine($"  Registered {name}Module in Program.cs.");
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

    private static async Task<int> RunProcessAsync(string fileName, string arguments, string workingDirectory)
    {
        using var process = new System.Diagnostics.Process();
        process.StartInfo = new System.Diagnostics.ProcessStartInfo
        {
            FileName = fileName,
            Arguments = arguments,
            WorkingDirectory = workingDirectory,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };

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
