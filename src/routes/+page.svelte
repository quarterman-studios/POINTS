<script lang="ts">
	import { goto } from '$app/navigation';
	import { enhance } from '$app/forms';
	import type { SubmitFunction } from '@sveltejs/kit';

	let { data, form } = $props();
	let { session, supabase } = $derived(data);

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

<h1>POINTS</h1>

<h2>LEADERBOARD</h2>

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
</style>
