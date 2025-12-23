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

	$inspect(leaderboard);
</script>

<h1>POINTS</h1>

<h2>LEADERBOARD</h2>

<section class="leaderboard">
	<h2>{session ? 'Your Rivals' : 'Top Players'}</h2>

	<ul>
		{#each leaderboard as player}
			<li class="row {userProfile?.username === player.username ? 'highlight' : ''}">
				<span class="rank">#{player.rank}</span>
				<span class="name">{player.username}</span>
				<span class="points">{player.points}</span>
			</li>
		{/each}
	</ul>
</section>

{#if signedIn}
	<form method="post" action="?/signout" use:enhance={handleSignOut}>
		<button aria-label="Sign Out">{loading ? 'Signing Out...' : 'Sign Out'}</button>
	</form>

	<button onclick={() => goto('/profile')}>Go to Profile</button>
{:else}
	<button type="button" aria-label="Sign In" onclick={() => goto('/login')}>Sign In</button>
{/if}

<style lang="scss">
	@use '../styles/variables' as *;

	h1 {
		font-size: 3rem;
		text-align: center;
		margin-top: 2rem;
		color: $text-primary;
	}

	h2 {
		font-size: 2rem;
		text-align: center;
		margin-top: 1rem;
		color: $text-secondary;
	}

	button {
		display: block;
		margin: 2rem auto;
		padding: 0.5rem 1rem;
		font-size: 1rem;
		background-color: $POINTS-COLOUR;
		color: $text-primary;
		border: none;
		border-radius: 5px;
		cursor: pointer;
		transition: background-color 0.3s;

		&:hover {
			background-color: $color-accent-hover;
		}
	}

	.row {
		display: flex;
		justify-content: space-between;
		padding: 0.5rem 1rem;
		border-bottom: 1px solid $text-secondary;

		&.highlight {
			background-color: rgba($POINTS-COLOUR, 0.2);
		}

		.rank, .name, .points {
			flex: 1;
			text-align: center;
		}
	}
</style>
