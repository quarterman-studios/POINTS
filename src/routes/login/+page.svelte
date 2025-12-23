<script lang="ts">
	import { enhance } from '$app/forms';
	import type { ActionData, PageData, SubmitFunction } from './$types';
	import GoogleButton from '$lib/components/GoogleButton.svelte';
	import { goto } from '$app/navigation';

	interface Props {
		form: ActionData;
		data: PageData;
	}

	let loading = $state(false);
	let googleLoading = $state(false);

	let { form, data }: Props = $props();

	const handleSubmit: SubmitFunction = () => {
		loading = true;
		return async ({ update }) => {
			update();
			loading = false;
		};
	};

	const handleGoogleSignIn = async () => {
		googleLoading = true;

		const { error } = await data.supabase.auth.signInWithOAuth({
			provider: 'google',
			options: {
				redirectTo: `${window.location.origin}/auth/confirm`
			}
		});

		if (error) {
			console.error('Error during Google sign-in:', error);
			loading = false;
		}
	};

	const handleBack = () => {
		goto('/');
	};

	$inspect({ form });
</script>

<div class="login-container">
	<h1>Sign In</h1>

	<form method="POST" action="?/magic-link-signin" use:enhance={handleSubmit}>
		<p>{'Sign in via magic link with your email below'}</p>

		<!-- TODO: Make username compulsory and check if username already exists for new users. -->
		<!-- TODO: Ask AI what to do if someone tries to sign in with your email from a different device -->

		<label for="username">Username: </label>
		<input name="username" id="username" type="text" />
		<label for="email">Email: </label>
		<input name="email" id="email" type="text" />
		<button aria-label="Submit Details">{loading ? 'Loading...' : 'Send Magic Link'}</button>
		<p>{form?.message || form?.errors?.email}</p>
		<div class="google-div">
			<GoogleButton loading={googleLoading} onClick={handleGoogleSignIn} />
		</div>
	</form>

	<button onclick={handleBack}>Back</button>
</div>

<style lang="scss">
	@use '../../styles/variables' as *;

	.login-container {
		max-width: 400px;
		margin: 2rem auto;
		padding: 2rem;
		background-color: $bg-card;
		border-radius: 10px;
		box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
		text-align: center;
	}

	form {
		display: flex;
		flex-direction: column;
		align-items: center;
		margin-top: 2rem;
		color: $text-primary;

		p {
			margin-bottom: 1rem;
		}

		label {
			margin-top: 0.5rem;
		}

		input {
			margin-bottom: 1rem;
			padding: 0.5rem;
			border: 1px solid $text-secondary;
			border-radius: 5px;
			width: 250px;
		}

		button {
			margin-top: 1rem;
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

		.google-div {
			margin-top: 1rem;
		}
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
