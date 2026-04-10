using Godot;

/// <summary>
/// Chama de queimadura — persiste 3 segundos no chão após laser não ser parado.
/// Dano contínuo ao player, respeita I-frame de dash.
/// </summary>
public partial class FireHazard : Area2D
{
    private const float Lifetime       = 3f;
    private const float DamagePerTick  = 400f;
    private const float DamageCooldown = 0.5f;

    private float _life  = Lifetime;
    private float _dmgCd = 0f;

    public override void _Ready()
    {
        CollisionLayer = 0;
        CollisionMask  = 2; // layer do player — ajuste se necessário

        var base_ = new ColorRect
        {
            Size     = new Vector2(48f, 18f),
            Position = new Vector2(-24f, -18f),
            Color    = new Color(1f, 0.35f, 0f, 0.85f)
        };
        AddChild(base_);

        var glow = new ColorRect
        {
            Size     = new Vector2(28f, 10f),
            Position = new Vector2(-14f, -26f),
            Color    = new Color(1f, 0.78f, 0f, 0.7f)
        };
        AddChild(glow);

        var shape = new CollisionShape2D();
        shape.Shape    = new RectangleShape2D { Size = new Vector2(48f, 18f) };
        shape.Position = new Vector2(0f, -9f);
        AddChild(shape);

        BodyEntered += OnBodyEntered;
    }

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;
        _life  -= dt;
        _dmgCd -= dt;

        if (_life < 0.8f)
            Modulate = new Color(1, 1, 1, Mathf.Sin(_life * 22f) * .5f + .5f);

        if (_life <= 0f) QueueFree();
    }

    private void OnBodyEntered(Node2D body)
    {
        if (_dmgCd > 0f) return;
        if (!body.IsInGroup("player") || !body.HasMethod("take_damage")) return;
        if (body.Get("is_dashing").AsBool()) return;

        body.Call("take_damage", DamagePerTick);
        _dmgCd = DamageCooldown;
    }
}
