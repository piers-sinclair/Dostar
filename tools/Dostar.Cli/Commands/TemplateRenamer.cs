namespace Dostar.Cli.Commands;

internal static class TemplateRenamer
{
    private const string GitDirectoryName = ".git";

    private static readonly string[] TextExtensions =
    [
        ".cs", ".csproj", ".slnx", ".sln", ".json", ".xml", ".config", ".yaml", ".yml",
        ".md", ".txt", ".sh", ".ps1", ".ts", ".tsx", ".js", ".jsx", ".html", ".css",
        ".scss", ".env", ".gitignore", ".gitattributes", ".editorconfig", ".props",
        ".targets", ".bicep", ".http", ".razor", ".cshtml", ".toml"
    ];

    internal static void Apply(string rootDir, string projectName)
    {
        var projectNameLower = projectName.ToLowerInvariant();
        RenameEntriesBottomUp(new DirectoryInfo(rootDir), projectName, projectNameLower);
        SubstituteInFiles(rootDir, projectName, projectNameLower);
    }

    private static void RenameEntriesBottomUp(DirectoryInfo dir, string projectName, string projectNameLower)
    {
        foreach (var subDir in dir.GetDirectories())
        {
            if (subDir.Name == GitDirectoryName)
                continue;

            RenameEntriesBottomUp(subDir, projectName, projectNameLower);

            var newName = Substitute(subDir.Name, projectName, projectNameLower);
            if (newName != subDir.Name)
                subDir.MoveTo(Path.Combine(subDir.Parent!.FullName, newName));
        }

        foreach (var file in dir.GetFiles())
        {
            var newName = Substitute(file.Name, projectName, projectNameLower);
            if (newName != file.Name)
                file.MoveTo(Path.Combine(file.DirectoryName!, newName));
        }
    }

    private static void SubstituteInFiles(string rootDir, string projectName, string projectNameLower)
    {
        var files = Directory.EnumerateFiles(rootDir, "*", SearchOption.AllDirectories)
            .Where(f => !IsUnderGitDirectory(rootDir, f))
            .Where(IsTextFile);

        foreach (var filePath in files)
        {
            try
            {
                var content = File.ReadAllText(filePath);
                var updated = Substitute(content, projectName, projectNameLower);
                if (updated != content)
                    File.WriteAllText(filePath, updated);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Warning: Could not process '{filePath}': {ex.Message}");
            }
        }
    }

    private static bool IsUnderGitDirectory(string rootDir, string filePath) =>
        Path.GetRelativePath(rootDir, filePath)
            .StartsWith(GitDirectoryName + Path.DirectorySeparatorChar, StringComparison.Ordinal);

    private static string Substitute(string input, string projectName, string projectNameLower) =>
        input
            .Replace("Dostar", projectName, StringComparison.Ordinal)
            .Replace("dostar", projectNameLower, StringComparison.Ordinal);

    private static bool IsTextFile(string filePath)
    {
        var ext = Path.GetExtension(filePath).ToLowerInvariant();
        if (TextExtensions.Contains(ext))
            return true;

        if (string.IsNullOrEmpty(ext))
        {
            var fileName = Path.GetFileName(filePath);
            return fileName is "Dockerfile" or "Makefile" or "LICENSE" or "NOTICE" or "AUTHORS";
        }

        return false;
    }
}
