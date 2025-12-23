<script lang="ts">
	import { enhance } from '$app/forms';
	import { goto } from '$app/navigation';
	import type { SubmitFunction } from '@sveltejs/kit';

	let { data, form } = $props();
	let { session, supabase } = $derived(data);
	let loading = $state(false);

	const handleSignOut: SubmitFunction = () => {
		loading = true;
		return async ({ update }) => {
			loading = false;
			update();
		};
	};
</script>

<div class="form-widget">
	<h2>Account Details</h2>
	<p>{session?.user.email}</p>

	<div>
		<input
			type="submit"
			class="button block primary"
			value={loading ? 'Loading...' : 'Update'}
			disabled={loading}
		/>
	</div>

	<form method="post" action="?/signout" use:enhance={handleSignOut}>
		<div>
			<button class="button block" disabled={loading}>Sign Out</button>
		</div>
	</form>

	<button onclick={() => goto('/')}>Attack</button>
</div>
