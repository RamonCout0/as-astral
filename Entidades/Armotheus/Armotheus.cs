using Godot;

/// <summary>
/// Boss Armotheus — C#
/// Tolerante a animações faltando: só toca a animação se ela existir no AnimatedSprite2D.
/// </summary>
public partial class Armotheus : CharacterBody2D
{
	[ExportGroup("Arena")]
	[Export] public float ArenaLeft  = 16f;
	[Export] public float ArenaRight = 464f;
	[Export] public float ArenaTop   = 16f;
	[Export] public float ArenaFloor = 252f;

	private const float MaxHp    = 304_000f;
	private const float HpPerBar =   1_000f;
	private float _hp;

	private const float MaxStagger       = 5_000f;
	private const float StaggerDecay     =    80f;
	private const float StaggerDrainRate = 1_500f;
	private float _stagger;

	private enum BossState { Idle, PenduloU, LaserEscarlate, Staggered, Dead }
	private BossState _state = BossState.Idle;

	[Export] public float AttackCooldown = 3.5f;
	private float _attackTimer;
	private int   _lastAttack = -1;

	[Export] public PackedScene LaserScene;
	[Export] public PackedScene FireHazardScene;

	private AnimatedSprite2D _anim;
	private Node2D           _player;
	private Node             _bus;

	private bool    _pendActive;
	private float   _pendT;
	private Vector2 _p0, _p1, _p2;
	private float   _pendDmgCd;

	private bool _laserActive;

	public override void _Ready()
	{
		AddToGroup("boss");

		_bus    = GetNode("/root/EventBus");
		_anim   = GetNodeOrNull<AnimatedSprite2D>("AnimatedSprite2D");
		_player = GetTree().GetFirstNodeInGroup("player") as Node2D;

		if (_player == null)
			GD.PushWarning("[Armotheus] Player não encontrado no grupo 'player'!");

		_hp          = MaxHp;
		_stagger     = 0f;
		_attackTimer = AttackCooldown;

		GlobalPosition = new Vector2((ArenaLeft + ArenaRight) * .5f, ArenaTop + 40f);

		_bus.EmitSignal("boss_max_health_set", MaxHp, HpPerBar);
		_bus.EmitSignal("boss_stagger_updated", 0f, MaxStagger);

		PlayAnim("idle");
	}

	public override void _PhysicsProcess(double delta)
	{
		if (_state == BossState.Dead) return;
		float dt = (float)delta;

		if (_state == BossState.Staggered)
		{
			_stagger -= StaggerDrainRate * dt;
			if (_stagger <= 0f) { _stagger = 0f; ExitStagger(); }
			_bus.EmitSignal("boss_stagger_updated", _stagger, MaxStagger);
			return;
		}

		_stagger = Mathf.Max(0f, _stagger - StaggerDecay * dt);
		_bus.EmitSignal("boss_stagger_updated", _stagger, MaxStagger);

		if (_state == BossState.PenduloU) TickPenduloU(dt);

		if (!_pendActive && !_laserActive)
		{
			_attackTimer -= dt;
			if (_attackTimer <= 0f) LaunchNextAttack();
		}
	}

	private void LaunchNextAttack()
	{
		int next     = (_lastAttack == 0) ? 1 : 0;
		_lastAttack  = next;
		_attackTimer = AttackCooldown;

		if (next == 0) StartPenduloU();
		else           StartLaserEscarlate();
	}

	// ── ATAQUE 1 — PÊNDULO U ─────────────────────────────────────────
	private void StartPenduloU()
	{
		_state      = BossState.PenduloU;
		_pendActive = true;
		_pendT      = 0f;
		_pendDmgCd  = 0f;

		bool fromLeft = GD.Randf() > .5f;
		_p0 = new Vector2(fromLeft ? ArenaLeft + 16f : ArenaRight - 16f, ArenaTop + 20f);
		_p2 = new Vector2(fromLeft ? ArenaRight - 16f : ArenaLeft + 16f, ArenaTop + 20f);
		_p1 = new Vector2((ArenaLeft + ArenaRight) * .5f, ArenaFloor - 8f);

		PlayAnim("attack");
	}

	private void TickPenduloU(float dt)
	{
		_pendT += dt * 1.2f;
		float t  = Mathf.Clamp(_pendT, 0f, 1f);
		float u  = 1f - t;
		Vector2 pos = u * u * _p0 + 2f * u * t * _p1 + t * t * _p2;

		GlobalPosition = new Vector2(
			Mathf.Clamp(pos.X, ArenaLeft,  ArenaRight),
			Mathf.Clamp(pos.Y, ArenaTop,   ArenaFloor)
		);

		_pendDmgCd -= dt;
		if (_player != null && IsInstanceValid(_player))
		{
			bool dashing = _player.Get("is_dashing").AsBool();
			float dist   = GlobalPosition.DistanceTo(_player.GlobalPosition);
			if (!dashing && dist < 36f && _pendDmgCd <= 0f)
			{
				_player.Call("take_damage", 2_500f);
				_pendDmgCd = 0.3f;
			}
		}

		if (_pendT >= 1f)
		{
			_pendActive    = false;
			_state         = BossState.Idle;
			GlobalPosition = new Vector2((ArenaLeft + ArenaRight) * .5f, ArenaTop + 40f);
			_attackTimer   = AttackCooldown;
			PlayAnim("idle");
		}
	}

	// ── ATAQUE 2 — LASER ─────────────────────────────────────────────
	private void StartLaserEscarlate()
	{
		_state       = BossState.LaserEscarlate;
		_laserActive = true;

		bool fromLeft = GD.Randf() > .5f;
		GlobalPosition = new Vector2(
			fromLeft ? ArenaLeft + 16f : ArenaRight - 16f,
			ArenaTop + 20f
		);

		PlayAnim("laser_warn");
		GetTree().CreateTimer(1.5f).Timeout += FireLaser;
	}

	private void FireLaser()
	{
		if (_state != BossState.LaserEscarlate || LaserScene == null)
		{
			OnLaserFinished();
			return;
		}

		PlayAnim("laser_fire");

		var laser = LaserScene.Instantiate<LaserEscarlate>();

		// ✅ CORRIGIDO: Initialize ANTES de AddChild, senão _Ready() roda sem dados
		laser.Initialize(
			GlobalPosition, _player,
			ArenaLeft, ArenaRight, ArenaFloor,
			FireHazardScene
		);

		GetParent().AddChild(laser);

		laser.Finished   += OnLaserFinished;
		laser.CounterHit += () => AddStagger(2_500f);
	}

	private void OnLaserFinished()
	{
		_laserActive = false;
		_state       = BossState.Idle;
		_attackTimer = AttackCooldown;
		PlayAnim("idle");
	}

	// ── DANO ─────────────────────────────────────────────────────────
	public void TakeDamage(float amount)
	{
		if (_state is BossState.Dead or BossState.Staggered) return;
		_hp = Mathf.Max(0f, _hp - amount);
		_bus.EmitSignal("boss_health_updated", _hp);
		AddStagger(amount * 0.5f);
		if (_hp <= 0f) Die();
	}

	// ── STAGGER ──────────────────────────────────────────────────────
	private void AddStagger(float amount)
	{
		if (_state is BossState.Staggered or BossState.Dead) return;
		_stagger = Mathf.Min(MaxStagger, _stagger + amount);
		_bus.EmitSignal("boss_stagger_updated", _stagger, MaxStagger);
		if (_stagger >= MaxStagger) EnterStagger();
	}

	private void EnterStagger()
	{
		_state       = BossState.Staggered;
		_pendActive  = false;
		_laserActive = false;
		_stagger     = MaxStagger;
		_bus.EmitSignal("boss_staggered");
		_bus.EmitSignal("boss_stagger_updated", _stagger, MaxStagger);
		PlayAnim("staggered");
	}

	private void ExitStagger()
	{
		_state       = BossState.Idle;
		_stagger     = 0f;
		_attackTimer = AttackCooldown;
		_bus.EmitSignal("boss_stagger_updated", 0f, MaxStagger);
		PlayAnim("idle");
	}

	private void Die()
	{
		_state = BossState.Dead;
		_bus.EmitSignal("boss_health_updated", 0f);
		PlayAnim("dead");
		GetTree().CreateTimer(1.5f).Timeout += QueueFree;
	}

	// ── HELPER ANIMAÇÃO ───────────────────────────────────────────────
	private void PlayAnim(string animName)
	{
		if (_anim == null) return;
		if (_anim.SpriteFrames != null && _anim.SpriteFrames.HasAnimation(animName))
			_anim.Play(animName);
	}
}
