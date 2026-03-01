import axios from 'axios';

// The new Go REST Gateway runs on port 8080
const REST_API_URL = 'http://localhost:8080/api';

export const GIPJAZES_API = {
    login: async (email: string, password: string) => {
        try {
            // NOTE: Our backend expects a `username` field for login, but we collected an `email`. 
            // For now, we'll map email to username just to hit the endpoint correctly.
            const response = await axios.post(`${REST_API_URL}/auth/login`, {
                username: email,
                password: password
            });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },

    register: async (username: string, email: string, password: string) => {
        try {
            const response = await axios.post(`${REST_API_URL}/auth/register`, {
                username,
                email,
                password
            });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },

    getFeed: async (userId?: string, category?: string) => {
        try {
            const params: any = {};
            if (userId) params.user_id = userId;
            if (category && category !== 'For You') params.category = category;
            const response = await axios.get(`${REST_API_URL}/feed`, { params });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },

    uploadVideo: async (file: File, token: string, description: string = 'Uploaded via Web') => {
        try {
            const formData = new FormData();
            formData.append('video', file);
            formData.append('description', description);

            const response = await axios.post(`${REST_API_URL}/upload`, formData, {
                headers: {
                    'Content-Type': 'multipart/form-data',
                    'Authorization': `Bearer ${token}`
                }
            });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },

    searchVideos: async (query: string) => {
        try {
            const response = await axios.get(`${REST_API_URL}/search`, {
                params: { q: query }
            });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    }
};
