<script lang="ts">
	import { goto } from '$app/navigation';
	import { enhance } from '$app/forms';
	import type { SubmitFunction } from '@sveltejs/kit';

	let { data } = $props();
	let { session, userProfile, leaderboard } = $derived(data);

	let loading = $state(false);
	let signedIn = $derived(!!session);

	const handleSignOut: SubmitFunction = () => {
		loading = true;
		return async ({ update }) => {
			loading = false;
			update();
		};
	};
</script>

<div class="page-container">
	{#if !signedIn}
		<section class="hero">
			<h1>"POINTS"</h1>

			<button class="btn-primary btn-large" onclick={() => goto('/login')}> SIGN IN </button>
		</section>
	{/if}

	{#if signedIn}
		<section class="title-section">
			<h2>LEADERBOARD</h2>
		</section>
		<section class="user-dashboard">
			<div class="stat-card">
				<span class="label">Rank</span>
				<span class="value">#{userProfile?.rank ?? '-'}</span>
			</div>
			<div class="stat-card">
				<span class="label">Points</span>
				<span class="value">{userProfile?.points ?? 0}</span>
			</div>

			<div class="actions">
				<button class="btn-text" onclick={() => goto('/profile')}>Profile</button>
			</div>
		</section>
	{/if}

	<section class="list-container">
		<div class="rows">
			{#each leaderboard as player}
				{@const isMe = userProfile?.username === player.username}

				<div class="row {isMe ? 'current-user' : ''}">
					<div class="left-section">
						<span class="rank">#{player.rank}</span>
						<div class="avatar-circle"></div>

						<div class="info">
							<span class="username">{player.username}</span>
						</div>
					</div>

					<div class="right-section">
						<span class="points-value">{player.points}</span>
						{#if signedIn && !isMe}
							<button class="btn-action">Attack</button>
						{/if}
					</div>
				</div>
			{/each}
		</div>
	</section>
</div>

<style lang="scss">
	@use '../styles/variables' as *;

	// Global Page Layout
	.page-container {
		max-width: 480px;
		margin: 0 auto;
		padding: $space-lg $space-md;
		min-height: 100vh;
		font-family: $font-stack;
		color: var(--text-primary);
	}

	// --- HERO SECTION (Public) ---
	.hero {
		text-align: center;
		// Uses the NEW variable for proper separation
		margin-bottom: $space-xl;
		padding-top: $space-lg;

		h1 {
			font-family: var(--font-header), sans-serif;
			font-size: 6rem;
			font-weight: $weight-bold;
			margin-bottom: $space-sm;
			letter-spacing: -0.05rem;
			color: var(--text-primary);
		}

		.btn-large {
			width: 30%;
			padding: 1em;
			font-size: 1em;
		}
	}

	.btn-action {
		@extend .btn-primary;
		padding: $space-xs $space-sm;
		font-size: 0.875rem;
		border-radius: $radius-pill;
		cursor: pointer;
	}

	.title-section {
		display: flex;
		justify-content: center;
		margin-bottom: $space-md;
		h2 {
			font-size: 1.5rem;
			font-weight: $weight-bold;
			letter-spacing: -0.05rem;
			color: var(--text-primary);
		}
	}

	// --- DASHBOARD (Private) ---
	.user-dashboard {
		display: grid;
		grid-template-columns: 1fr 1fr auto;
		gap: $space-md;
		margin-bottom: $space-xl; // Uses NEW variable
		align-items: center;
		background-color: var(--bg-surface);
		padding: $space-md;
		border-radius: $radius-md;
		border: 1px solid var(--border-color);
	}

	.stat-card {
		display: flex;
		flex-direction: column;
		.label {
			font-size: 11px;
			color: var(--text-secondary);
			text-transform: uppercase;
		}
		.value {
			font-size: 20px;
			font-weight: $weight-bold;
			color: var(--text-primary);
		}
	}

	.actions {
		display: flex;
		flex-direction: column;
		gap: 4px;
		align-items: flex-end;
	}

	// --- LIST CONTAINER ---
	.list-container {
		position: relative;
	}

	.list-header {
		display: flex;
		justify-content: space-between;
		color: var(--text-secondary);
		font-size: 12px;
		text-transform: uppercase;
		letter-spacing: 0.5px;
		padding-bottom: $space-sm;
		border-bottom: 1px solid var(--border-color);
		margin-bottom: $space-xs;
	}

	// --- THE ROW ---
	.row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: $space-sm;
		border: 1px solid var(--border-color);
		border-radius: $radius-sm;
		margin-bottom: $space-sm;

		transition: all 0.2s;

		&:hover {
			background-color: var(--bg-surface-hover);
		}

		transition: background-color 0.2s;

		&.current-user {
			border-left: 2px solid var(--color-accent);
			padding-left: 8px;
			background: linear-gradient(90deg, rgba(var(--color-accent), 0.05) 0%, transparent 100%);
		}
	}

	.left-section,
	.right-section {
		display: flex;
		align-items: center;
		gap: 12px;
	}

	.rank {
		color: var(--text-secondary);
		width: 24px;
		font-variant-numeric: tabular-nums;
		font-size: 14px;
	}

	.avatar-circle {
		width: 32px;
		height: 32px;
		border-radius: 50%;
		background-color: var(--bg-surface);
		border: 1px solid var(--border-color);
	}

	.info {
		display: flex;
		flex-direction: column;
		gap: 2px;

		.username {
			font-weight: $weight-medium;
			font-size: 15px;
		}
	}

	.points-value {
		font-weight: var(--weight-medium);
		font-variant-numeric: tabular-nums;
	}
</style>
