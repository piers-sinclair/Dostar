namespace Dostar.Todos.UnitTests;

public class UpdateTodoRequestValidatorTests
{
    private readonly Fixture _fixture = new();
    private readonly UpdateTodoRequestValidator _sut = new();

    [Fact]
    public async Task Validate_WhenTitleIsValid_ReturnsValid()
    {
        var request = _fixture.Create<UpdateTodoRequest>();

        var result = await _sut.ValidateAsync(request);

        result.IsValid.ShouldBeTrue();
    }

    [Fact]
    public async Task Validate_WhenTitleIsEmpty_ReturnsInvalid()
    {
        var request = new UpdateTodoRequest(string.Empty, false);

        var result = await _sut.ValidateAsync(request);

        result.IsValid.ShouldBeFalse();
        result.Errors.ShouldContain(e => e.PropertyName == nameof(UpdateTodoRequest.Title));
    }

    [Fact]
    public async Task Validate_WhenTitleExceedsMaxLength_ReturnsInvalid()
    {
        var request = new UpdateTodoRequest(new string('a', 201), false);

        var result = await _sut.ValidateAsync(request);

        result.IsValid.ShouldBeFalse();
        result.Errors.ShouldContain(e => e.PropertyName == nameof(UpdateTodoRequest.Title));
    }

    [Fact]
    public async Task Validate_WhenTitleIsExactlyMaxLength_ReturnsValid()
    {
        var request = new UpdateTodoRequest(new string('a', 200), true);

        var result = await _sut.ValidateAsync(request);

        result.IsValid.ShouldBeTrue();
    }
}
