<script lang="ts">
	import { onMount } from 'svelte';
	import { invalidate } from '$app/navigation';


	let { data, children } = $props();
	let {supabase, session} = $derived(data);

	onMount(() => {
		const {data} = supabase.auth.onAuthStateChange((event, _session) => {
			if(_session?.expires_at !== session?.expires_at) {
				invalidate('supabase:auth');
			}
		})
	});
</script>

<svelte:head>
	<title>POINTS</title>
</svelte:head>

{@render children()}