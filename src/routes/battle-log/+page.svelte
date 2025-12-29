<script lang="ts">
	import { enhance } from '$app/forms';
	import { goto } from '$app/navigation';
	import type { SubmitFunction } from '@sveltejs/kit';

	let { data } = $props();
	let { session } = $derived(data);
</script>

<main class="content-wrapper">
	<section class="battle-log-section">
		<h2>BATTLE LOG</h2>
		<p>Your recent battles will appear here.</p>
	</section>

	<button class="btn-back-to-profile" onclick={() => goto('/profile')}>Back to Profile</button>
</main>

<style lang="scss">
	@use '../../styles/_variables.scss' as *;

	.content-wrapper {
		padding: $space-lg;
		display: flex;
		flex-direction: column;
		gap: $space-lg;
	}

	.battle-log-section {
		background-color: var(--bg-surface);
		padding: $space-md;
		border-radius: $radius-md;
		box-shadow: var(--shadow-sm);

		h2 {
			margin-bottom: $space-sm;
		}

		p {
			color: var(--text-secondary);
		}
	}

	.btn-back-to-profile {
		@extend .btn-primary;
		width: fit-content;
	}
</style>
