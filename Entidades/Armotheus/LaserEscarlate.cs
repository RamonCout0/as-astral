using Godot;

/// <summary>
/// Laser da Varredura Escarlate.
/// Initialize() deve ser chamado ANTES de AddChild() para que _Ready() já tenha os dados.
/// </summary>
public partial class LaserEscarlate : Node2D
{
    [Signal] public delegate void FinishedEventHandler();
    [Signal] public delegate void CounterHitEventHandler();

    private const float SweepSpeed    = 150f;
    private const float ParryRange    =  72f;
    private const float ContactDamage = 1_800f;

    private Node2D      _player;
    private Node        _bus;
    private PackedScene _fireScene;

    private float   _arenaLeft, _arenaRight, _arenaFloor;
    private Vector2 _origin;

    private enum Phase { Warn, Sweep, Done }
    private Phase _phase     = Phase.Warn;
    private float _warnTimer = 0.4f;

    private float _sweepX;
    private float _sweepTarget;
    private float _sweepDir;

    private bool     _parryOpen = false;
    private Line2D   _line;
    private Callable _counterCallable; // ✅ guardado como campo para Disconnect funcionar

    // Chamado ANTES de AddChild — dados já disponíveis quando _Ready() rodar
    public void Initialize(
        Vector2 origin, Node2D player,
        float left, float right, float floor,
        PackedScene fireScene)
    {
        _origin     = origin;
        _player     = player;
        _arenaLeft  = left;
        _arenaRight = right;
        _arenaFloor = floor;
        _fireScene  = fireScene;
    }

    public override void _Ready()
    {
        GlobalPosition = _origin;

        _bus = GetNode("/root/EventBus");

        _line = new Line2D
        {
            DefaultColor = new Color(1f, 0.08f, 0.05f, 0.95f),
            Width        = 6f,
        };
        AddChild(_line);

        // ✅ Guardado como campo para poder fazer Disconnect depois
        _counterCallable = Callable.From(OnCounter);
        _bus.Connect("player_counter_pressed", _counterCallable);

        // Boss em qual lado? Laser começa no lado OPOSTO do chão
        bool bossLeft = _origin.X < (_arenaLeft + _arenaRight) * .5f;
        _sweepX      = bossLeft ? _arenaRight - 16f : _arenaLeft + 16f;
        _sweepTarget = _player?.GlobalPosition.X ?? (_arenaLeft + _arenaRight) * .5f;
        _sweepDir    = Mathf.Sign(_sweepTarget - _sweepX);
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_phase == Phase.Done) return;
        float dt = (float)delta;

        switch (_phase)
        {
            case Phase.Warn:
                _warnTimer -= dt;
                if (_warnTimer <= 0f) { _phase = Phase.Sweep; _parryOpen = true; }
                break;
            case Phase.Sweep:
                TickSweep(dt);
                break;
        }

        RedrawLaser();
    }

    private void TickSweep(float dt)
    {
        _sweepX += _sweepDir * SweepSpeed * dt;

        bool reached = _sweepDir > 0f
            ? _sweepX >= _sweepTarget
            : _sweepX <= _sweepTarget;

        if (reached)
        {
            _parryOpen = false;
            bool dashing = _player != null && _player.Get("is_dashing").AsBool();

            if (!dashing && _player != null && IsInstanceValid(_player))
            {
                _player.Call("take_damage", ContactDamage);
                SpawnFire(_player.GlobalPosition.X);
            }
            End();
            return;
        }

        if (_sweepX < _arenaLeft || _sweepX > _arenaRight) End();
    }

    private void OnCounter()
    {
        if (!_parryOpen || _phase != Phase.Sweep) return;
        if (_player == null || !IsInstanceValid(_player)) return;

        float distToBeam = Mathf.Abs(_player.GlobalPosition.X - _sweepX);
        if (distToBeam > ParryRange) return;

        _parryOpen = false;
        EmitSignal(SignalName.CounterHit);
        End();
    }

    private void RedrawLaser()
    {
        if (_line == null) return;
        _line.ClearPoints();
        _line.AddPoint(Vector2.Zero);
        _line.AddPoint(new Vector2(_sweepX - _origin.X, _arenaFloor - _origin.Y));
    }

    private void SpawnFire(float x)
    {
        if (_fireScene == null) return;
        var fire = _fireScene.Instantiate<FireHazard>();
        GetParent().AddChild(fire);
        fire.GlobalPosition = new Vector2(x, _arenaFloor - 12f);
    }

    private void End()
    {
        if (_phase == Phase.Done) return;
        _phase = Phase.Done;
        DisconnectCounter();
        _line?.ClearPoints();
        EmitSignal(SignalName.Finished);
        QueueFree();
    }

    private void DisconnectCounter()
    {
        if (_bus == null) return;
        // ✅ Usa o mesmo callable guardado — IsConnected funciona corretamente
        if (_bus.IsConnected("player_counter_pressed", _counterCallable))
            _bus.Disconnect("player_counter_pressed", _counterCallable);
    }

    public override void _ExitTree() => DisconnectCounter();
}
