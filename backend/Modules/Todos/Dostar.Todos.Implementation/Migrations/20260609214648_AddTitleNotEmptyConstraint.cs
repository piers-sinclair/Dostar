using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Dostar.Todos.Implementation.Migrations
{
    /// <inheritdoc />
    public partial class AddTitleNotEmptyConstraint : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddCheckConstraint(
                name: "CK_Todos_Title_NotEmpty",
                table: "Todos",
                sql: "\"Title\" <> ''");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_Todos_Title_NotEmpty",
                table: "Todos");
        }
    }
}
