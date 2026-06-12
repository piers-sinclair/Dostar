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
        var request = _fixture.Build<UpdateTodoRequest>().With(x => x.Title, string.Empty).Create();

        var result = await _sut.ValidateAsync(request);

        result.IsValid.ShouldBeFalse();
        result.Errors.ShouldContain(e => e.PropertyName == nameof(UpdateTodoRequest.Title));
    }

    [Fact]
    public async Task Validate_WhenTitleExceedsMaxLength_ReturnsInvalid()
    {
        var request = _fixture.Build<UpdateTodoRequest>().With(x => x.Title, new string('a', 201)).Create();

        var result = await _sut.ValidateAsync(request);

        result.IsValid.ShouldBeFalse();
        result.Errors.ShouldContain(e => e.PropertyName == nameof(UpdateTodoRequest.Title));
    }

    [Fact]
    public async Task Validate_WhenTitleIsExactlyMaxLength_ReturnsValid()
    {
        var request = _fixture.Build<UpdateTodoRequest>().With(x => x.Title, new string('a', 200)).Create();

        var result = await _sut.ValidateAsync(request);

        result.IsValid.ShouldBeTrue();
    }
}
