import {
    InteractionRequiredAuthError,
    PublicClientApplication,
    type Configuration,
    type SilentRequest,
} from '@azure/msal-browser';

const msalConfig: Configuration = {
    auth: {
        clientId: import.meta.env.VITE_AZURE_CLIENT_ID,
        authority: `https://login.microsoftonline.com/${import.meta.env.VITE_AZURE_TENANT_ID}`,
        redirectUri: window.location.origin,
    },
    cache: {
        cacheLocation: 'sessionStorage',
    },
};

export const msalInstance = new PublicClientApplication(msalConfig);

export const apiTokenRequest: SilentRequest = {
    scopes: [`api://${import.meta.env.VITE_AZURE_CLIENT_ID}/access_as_user`],
};

export async function getAccessToken(): Promise<string> {
    const account = msalInstance.getActiveAccount() ?? msalInstance.getAllAccounts()[0];

    if (!account) {
        await msalInstance.loginRedirect(apiTokenRequest);
        return '';
    }

    try {
        const { accessToken } = await msalInstance.acquireTokenSilent({
            ...apiTokenRequest,
            account,
        });
        return accessToken;
    } catch (err) {
        if (err instanceof InteractionRequiredAuthError) {
            await msalInstance.acquireTokenRedirect({ ...apiTokenRequest, account });
        }
        return '';
    }
}
