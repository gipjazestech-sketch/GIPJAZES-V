import axios from 'axios';

// The API Gateway runs on port 8080 locally, but uses VITE_API_URL in production (Vercel)
// Production Render Backend URL
const REST_API_URL = import.meta.env.VITE_API_URL || 'https://gipjazes-v-api.onrender.com/api';

export const GIPJAZES_API = {
    login: async (email: string, password: string) => {
        try {
            const response = await axios.post(`${REST_API_URL}/auth/login`, {
                email: email,
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

    uploadAvatar: async (file: File, token: string) => {
        try {
            const formData = new FormData();
            formData.append('avatar', file);

            const response = await axios.post(`${REST_API_URL}/profile/avatar`, formData, {
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
    },

    getProfile: async (token: string, userId?: string) => {
        try {
            const response = await axios.get(`${REST_API_URL}/profile`, {
                params: { user_id: userId },
                headers: { 'Authorization': `Bearer ${token}` }
            });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },

    getComments: async (videoId: string) => {
        try {
            const response = await axios.get(`${REST_API_URL}/comments`, {
                params: { video_id: videoId }
            });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },

    createComment: async (token: string, videoId: string, content: string) => {
        if (!token) throw new Error("Authentication required");
        try {
            const response = await axios.post(`${REST_API_URL}/comments`, {
                video_id: videoId,
                content: content
            }, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            return response.data; // { success: true, new_count: X }
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },

    toggleLike: async (token: string, videoId: string) => {
        if (!token) throw new Error("Authentication required");
        try {
            const response = await axios.post(`${REST_API_URL}/like`, {
                video_id: videoId
            }, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            return response.data; // { success: true, is_liked: X, new_count: Y }
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },
    repost: async (token: string, videoId: string) => {
        try {
            const response = await axios.post(`${REST_API_URL}/repost`, {
                video_id: videoId
            }, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },
    updateProfile: async (token: string, data: { username?: string, display_name?: string, bio?: string, avatar_url?: string }) => {
        try {
            const response = await axios.post(`${REST_API_URL}/profile/update`, data, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },
    deleteAccount: async (token: string) => {
        try {
            const response = await axios.post(`${REST_API_URL}/user/delete`, {}, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },
    forgotPassword: async (email: string) => {
        try {
            const response = await axios.post(`${REST_API_URL}/auth/forgot-password`, { email });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },
    resetPassword: async (token: string, newPassword: string) => {
        try {
            const response = await axios.post(`${REST_API_URL}/auth/reset-password`, { token, new_password: newPassword });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },
    incrementView: async (videoId: string) => {
        try {
            await axios.post(`${REST_API_URL}/video/view`, { video_id: videoId });
        } catch (e) {}
    },
    sendGift: async (token: string, receiverId: string, amount: number) => {
        try {
            const response = await axios.post(`${REST_API_URL}/wallet/gift`, { receiver_id: receiverId, amount }, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },
    getNotifications: async (token: string) => {
        if (!token) throw new Error("Authentication required");
        try {
            const response = await axios.get(`${REST_API_URL}/notifications`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },
    startLive: async (token: string, title: string) => {
        if (!token) throw new Error("Authentication required");
        try {
            const response = await axios.post(`${REST_API_URL}/live/start`, { title }, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    },
    getLiveBroadcasts: async () => {
        try {
            const response = await axios.get(`${REST_API_URL}/live/list`);
            return response.data;
        } catch (error: any) {
            throw new Error(error.response?.data || error.message);
        }
    }
};
