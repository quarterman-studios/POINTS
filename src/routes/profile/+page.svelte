<script lang="ts">
	import { enhance } from '$app/forms';
	import { goto } from '$app/navigation';
	import type { SubmitFunction } from '@sveltejs/kit';

	let { data } = $props();
	let { session, userState, userProfile } = $derived(data);

	let signoutLoading = $state(false);

	// Safe data access for the template
	// We do this logic in the script to prevent template crashes
	let safeUsername = $derived(userProfile?.username || 'Guest');
	let safeInitials = $derived(safeUsername.substring(0, 2).toUpperCase());
</script>

<main class="content-wrapper">
	<section class="top-panel">
		<div class="stats-header">
			<div class="stat">
				<span class="label">PREROLL</span>
				<span class="value">{userState?.last_preroll_value ?? 0}</span>
			</div>
			<div class="stat">
				<span class="label">STREAKS</span>
				<span class="value">{userState?.streak ?? 0}</span>
			</div>
			<div class="stat">
				<span class="label">RANK</span>
				<span class="value">#{userProfile?.rank ?? '-'}</span>
			</div>
			<div class="stat">
				<span class="label">HIT TOLERANCE</span>
				<span class="value">{userState?.hit_tolerance ?? 0}</span>
			</div>
		</div>

		<div class="hero-display">
			<div class="avatar-container">
				<div class="avatar-circle">
					{safeInitials}
				</div>
				<button class="edit-btn" aria-label="Edit">
					<svg
						xmlns="http://www.w3.org/2000/svg"
						width="14"
						height="14"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
						stroke-linecap="round"
						stroke-linejoin="round"
						><path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z" /></svg
					>
				</button>
			</div>

			<div class="points-display">
				<span class="label">POINTS</span>
				<h1 class="glitch-text">{userProfile?.points?.toLocaleString() ?? 0}</h1>
			</div>
		</div>
	</section>

	<div class="floating-action">
		<button class="btn-battle-log" onclick={() => goto('/battle-log')}>View Battle Log</button>
	</div>
</main>

<style lang="scss">
	@use '../../styles/variables' as *;

	// Reset for this page to ensure no global scroll
	:global(body) {
		overflow: hidden;
		margin: 0;
	}

	// --- MAIN CONTENT ---
	.content-wrapper {
		display: flex;
		flex-direction: column;
		position: relative;
		height: 100vh;
		overflow: hidden; // Prevents outer scrolling
	}

	// --- TOP PANEL (Fixed) ---
	.top-panel {
		padding: $space-xl;
		padding-bottom: 0;
		flex-shrink: 0;
	}

	.stats-header {
		display: flex;
		justify-content: center;
		gap: $space-2xl;
		margin-bottom: $space-xl;

		.stat {
			display: flex;
			flex-direction: column;
			align-items: center;
			.label {
				font-size: 11px;
				color: var(--text-secondary);
				letter-spacing: 1px;
				margin-bottom: 4px;
			}
			.value {
				font-size: 16px;
				font-weight: var(--weight-bold);
				font-variant-numeric: tabular-nums;
			}
		}
	}

	.hero-display {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: $space-2xl;
		margin-bottom: $space-lg;

		.points-display {
			text-align: left;
			.label {
				font-size: 12px;
				color: var(--text-secondary);
				text-transform: uppercase;
			}
			h1 {
				font-size: 64px;
				font-weight: var(--weight-bold);
				letter-spacing: -2px;
				margin: 0;
				line-height: 1;
			}
		}
	}

	.avatar-container {
		position: relative;

		.avatar-circle {
			width: 100px;
			height: 100px;
			background-color: var(--bg-surface);
			border: 2px solid var(--border-color);
			border-radius: 50%;
			display: flex;
			align-items: center;
			justify-content: center;
			font-size: 24px;
			font-weight: var(--weight-bold);
			color: var(--text-secondary);
		}

		.edit-btn {
			position: absolute;
			bottom: 0;
			right: 0;
			background-color: var(--bg-surface-hover);
			border: 1px solid var(--border-color);
			color: var(--text-primary);
			width: 32px;
			height: 32px;
			border-radius: 50%;
			display: flex;
			align-items: center;
			justify-content: center;
			cursor: pointer;
			transition: all 0.2s;

			&:hover {
				border-color: var(--color-accent);
				color: var(--color-accent);
			}
		}
	}

	// --- FLOATING ACTION ---
	.floating-action {
		position: absolute;
		bottom: $space-lg;
		left: 50%;
		transform: translateX(-50%);
		z-index: 20;
	}

	.btn-battle-log {
		@extend .btn-primary;
		cursor: pointer;
		transition: all 0.2s;

		&:hover {
			background-color: var(--text-primary);
		}
	}
</style>
