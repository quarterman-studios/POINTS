import type { Actions } from "@sveltejs/kit"

export const actions: Actions = {
	default: async ({ request, locals }) => {
		const data = await request.formData();
		const info = locals;
		
		console.log(data);
		console.log(locals);

	}

}