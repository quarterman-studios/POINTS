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
			<p class="label">Steal points from other players</p>
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

			<button class="btn-text" onclick={() => goto('/profile')}>Profile</button>
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
							<button class="btn-action">STEAL</button>
						{/if}
					</div>
				</div>
			{/each}
		</div>
	</section>
</div>

<style lang="scss">
	// Import variables AND the new mixins file
	@use '../styles/variables' as *;
	@use '../styles/mixins' as *;

	// --- GLOBAL PAGE LAYOUT ---
	.page-container {
		width: 100%; // Default: take up full width on mobile
		padding: $space-md; // Default: smaller padding for mobile
		min-height: 100vh;
		font-family: $font-stack;
		color: var(--text-primary);
		margin: 0 auto;

		// On Tablet/Desktop: Restrict width and increase padding
		@include respond-to('tablet') {
			max-width: calc($width-max / 16 * 10);
			padding: $space-lg;
		}
	}

	// --- HERO SECTION (Public) ---
	.hero {
		text-align: center;
		margin-bottom: $space-xl;
		padding-top: $space-xl; // Give it breathing room on mobile

		h1 {
			font-family: var(--font-header), sans-serif;
			font-weight: $weight-bold;
			letter-spacing: -0.05rem;
			color: var(--text-primary);
			margin-bottom: $space-md;

			// RESPONSIVE TYPOGRAPHY
			font-size: 3.5rem; // Mobile size
			line-height: 1.1;

			@include respond-to('tablet') {
				font-size: 6rem; // Original massive size for desktop
			}
		}

		// RESPONSIVE BUTTON
		.btn-large {
			width: 100%; // Mobile: Full width for easy thumb reach
			padding: 1em;
			font-size: 1em;

			@include respond-to('tablet') {
				width: auto; // Desktop: Let content define width
				min-width: 200px;
			}
		}
	}

	.btn-action {
		@extend .btn-primary;
		padding: $space-xs $space-sm;
		font-size: 0.75rem; // Slightly smaller on mobile
		border-radius: $radius-pill;
		cursor: pointer;
		white-space: nowrap; // Prevent button text wrapping

		@include respond-to('tablet') {
			font-size: 0.875rem;
		}
	}

	.title-section {
		display: flex;
		flex-direction: column;
		align-items: center;
		margin-bottom: $space-md;
		text-align: center;

		h2 {
			font-size: 1.25rem;
			font-weight: $weight-bold;
			letter-spacing: -0.05rem;
			color: var(--text-primary);
			margin-top: $space-sm;

			@include respond-to('tablet') {
				font-size: 1.5rem;
			}
		}

		.label {
			font-size: 0.75rem;
			color: var(--text-secondary);
			text-transform: uppercase;

			@include respond-to('tablet') {
				font-size: 0.875rem;
			}
		}
	}

	// --- DASHBOARD (Private) ---
	.user-dashboard {
		// MOBILE DEFAULT: Stack vertically
		display: flex;
		flex-direction: row;
		justify-content: space-around;

		margin-bottom: $space-xl;
		background-color: var(--bg-surface);
		padding: $space-md;
		border-radius: $radius-md;
		border: 1px solid var(--border-color);

		// TABLET+: Switch to Grid
		@include respond-to('tablet') {
			display: grid;
			grid-template-columns: 1fr 1fr auto;
			align-items: center;
		}
	}

	.stat-card {
		display: flex;
		flex-direction: column;
		// Mobile: Center text for impact
		align-items: center;

		.label {
			font-size: 0.8rem;
			color: var(--text-secondary);
			text-transform: uppercase;
		}
		.value {
			font-size: 1.3rem; // Bigger numbers are good on mobile
			font-weight: $weight-bold;
			color: var(--text-primary);
		}

		@include respond-to('tablet') {
			font-size: 1.5rem;
			align-items: flex-start; // Reset to left align on desktop
		}
	}

	// --- LIST CONTAINER ---
	.list-container {
		position: relative;
		height: 55vh; // Fixed height for scrollable area
		overflow-y: auto;
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
		gap: $space-sm; // Ensure space between left/right sections
		transition: all 0.2s;

		&:hover {
			background-color: var(--bg-surface-hover);
		}

		&.current-user {
			border-left: 2px solid var(--color-accent);
			background: linear-gradient(90deg, rgba(var(--color-accent), 0.05) 0%, transparent 100%);
		}
	}

	.left-section {
		display: flex;
		align-items: center;
		gap: $space-sm;
		min-width: 0; // Fixes flexbox text overflow issues
	}

	.right-section {
		display: flex;
		align-items: center;
		gap: $space-sm;
		flex-shrink: 0; // Prevents points/button from squishing
	}

	.rank {
		color: var(--text-secondary);
		width: 1.5rem; // Reduce width slightly on mobile
		font-variant-numeric: tabular-nums;
		font-size: 0.875rem;

		@include respond-to('tablet') {
			width: $space-xl;
			font-size: 1rem;
		}
	}

	.avatar-circle {
		// Mobile: Smaller avatar
		width: 2rem;
		height: 2rem;
		border-radius: 50%;
		background-color: var(--bg-surface);
		border: 1px solid var(--border-color);
		flex-shrink: 0;

		@include respond-to('tablet') {
			width: $space-xl; // 2.5rem
			height: $space-xl;
		}
	}

	.info {
		display: flex;
		flex-direction: column;
		gap: 0;
		overflow: hidden; // Handle long usernames

		.username {
			font-weight: $weight-medium;
			font-size: 0.875rem;
			white-space: nowrap;
			overflow: hidden;
			text-overflow: ellipsis; // "Userna..."

			@include respond-to('tablet') {
				font-size: 1rem;
			}
		}
	}

	.points-value {
		font-weight: $weight-medium; // corrected var usage
		font-variant-numeric: tabular-nums;
		font-size: 0.875rem;

		@include respond-to('tablet') {
			font-size: 1rem;
		}
	}

	// Helper button text style
	.btn-text {
		font-family: $font-stack;
		background: none;
		border: none;
		color: var(--text-secondary);
		font-size: 0.875rem;
		cursor: pointer;

		&:hover {
			color: var(--text-primary);
			text-decoration: underline;
		}
	}
</style>
