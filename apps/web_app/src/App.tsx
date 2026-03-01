import { useState, useRef, useEffect } from 'react';
import { motion, useInView, AnimatePresence } from 'framer-motion';
import { Heart, MessageCircle, Share2, Compass, Home, User, Video, PlusSquare, Music, Play, Bookmark, X, Mail, Lock, UploadCloud, Film, Key, Search } from 'lucide-react';
import { GIPJAZES_API } from './lib/api';
import './index.css';

const categories = ["Comedy", "Music", "Gaming", "Tech", "Travel", "Food"];

// Removed mockFeed in favor of live DB connection

const Sidebar = ({
  activeTab,
  setActiveTab,
  onOpenUpload
}: {
  activeTab: string,
  setActiveTab: (tab: string) => void,
  onOpenUpload: () => void
}) => {
  const navItems = [
    { name: 'For You', icon: Home },
    { name: 'Explore', icon: Compass },
    { name: 'Live', icon: Video },
    { name: 'Profile', icon: User }
  ];

  return (
    <motion.div
      initial={{ x: -200, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
      className="sidebar"
    >
      <div className="brand-text" style={{ fontSize: '1.8rem', fontWeight: 800, marginBottom: '50px', color: 'var(--text-main)', letterSpacing: '1px' }}>
        GIPJAZES<span style={{ color: 'var(--brand-primary)' }}>.V</span>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', flex: 1 }}>
        {navItems.map((item) => (
          <div
            key={item.name}
            className={`nav-item ${activeTab === item.name ? 'active' : ''}`}
            onClick={() => setActiveTab(item.name)}
          >
            <item.icon size={22} style={{ strokeWidth: activeTab === item.name ? 2.5 : 2 }} />
            <span>{item.name}</span>
          </div>
        ))}
      </div>

      <div style={{ marginTop: '30px', borderTop: '1px solid rgba(255,255,255,0.05)', paddingTop: '20px', marginBottom: '30px' }}>
        <p style={{ color: 'var(--text-muted)', fontSize: '0.8rem', fontWeight: 600, paddingLeft: '15px', marginBottom: '15px', textTransform: 'uppercase', letterSpacing: '1px' }}>Discover</p>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', padding: '0 10px' }}>
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setActiveTab(cat)}
              style={{
                background: activeTab === cat ? 'rgba(255,0,229,0.1)' : 'rgba(255,255,255,0.05)',
                border: `1px solid ${activeTab === cat ? 'var(--brand-primary)' : 'rgba(255,255,255,0.1)'}`,
                color: activeTab === cat ? 'var(--brand-primary)' : 'white',
                borderRadius: '20px',
                padding: '6px 14px',
                fontSize: '0.8rem',
                cursor: 'pointer',
                transition: 'all 0.2s',
                outline: 'none'
              }}
            >
              # {cat}
            </button>
          ))}
        </div>
      </div>

      <motion.button
        whileHover={{ scale: 1.03 }}
        whileTap={{ scale: 0.97 }}
        className="upload-button"
        onClick={onOpenUpload}
      >
        <PlusSquare size={20} style={{ strokeWidth: 2.5 }} /> Upload
      </motion.button>
    </motion.div>
  );
};

const AuthModal = ({ isOpen, onClose, onSuccess }: { isOpen: boolean, onClose: () => void, onSuccess: (token: string) => void }) => {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  if (!isOpen) return null;

  const handleSubmit = async () => {
    try {
      if (isLogin) {
        console.log(`Submitting Login: Email: ${email}, Password: ${password}`);
        const result = await GIPJAZES_API.login(email, password);
        alert(`Welcome back! Session Token: ${result.token.substring(0, 10)}...`);
        onSuccess(result.token);
      } else {
        console.log(`Submitting Register: Email: ${email}, Username: ${username}, Password: ${password}`);
        const result = await GIPJAZES_API.register(username, email, password);
        alert(`Registration successful! Session Token: ${result.token.substring(0, 10)}...`);
        onSuccess(result.token);
      }
      onClose();
    } catch (e: any) {
      alert(`Error: ${e.message}`);
      console.error(e);
    }
  };

  return (
    <div className="modal-overlay">
      <motion.div
        initial={{ opacity: 0, scale: 0.9, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.9, y: 20 }}
        className="modal-content"
      >
        <button className="modal-close" onClick={onClose}><X size={28} /></button>
        <h2 className="modal-title">{isLogin ? 'Welcome Back' : 'Join GIPJAZES'}</h2>
        <p className="modal-subtitle">
          {isLogin ? 'Log in to continue your journey.' : 'Register to upload and save you favorite content.'}
        </p>

        <div className="form-group">
          <div className="form-input-container">
            <Mail className="form-icon" size={20} />
            <input
              type="email"
              placeholder="Email Address"
              className="form-input"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
        </div>

        {!isLogin && (
          <div className="form-group">
            <div className="form-input-container">
              <User className="form-icon" size={20} />
              <input
                type="text"
                placeholder="Username"
                className="form-input"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
              />
            </div>
          </div>
        )}

        <div className="form-group">
          <div className="form-input-container">
            <Lock className="form-icon" size={20} />
            <input
              type="password"
              placeholder="Password"
              className="form-input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>
        </div>

        <div className="key-btn-container" onClick={handleSubmit}>
          <div className="key-svg-wrapper">
            <Key size={34} color="var(--brand-primary)" strokeWidth={2.5} />
          </div>
          <div className="key-label">{isLogin ? 'Unlock GIPJAZES' : 'Initialize Access'}</div>
        </div>

        <div className="toggle-form">
          {isLogin ? "Don't have an account? " : "Already have an account? "}
          <span onClick={() => setIsLogin(!isLogin)}>
            {isLogin ? 'Sign Up' : 'Log In'}
          </span>
        </div>
      </motion.div>
    </div>
  );
};

const UploadModal = ({ isOpen, onClose, token }: { isOpen: boolean, onClose: () => void, token: string }) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);

  if (!isOpen) return null;

  const handleSelectFileClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setSelectedFile(e.target.files[0]);
    }
  };

  const handleUploadSubmit = async () => {
    if (!token) {
      alert("Please log in first before uploading videos!");
      return;
    }
    if (selectedFile) {
      try {
        await GIPJAZES_API.uploadVideo(selectedFile, token, "Direct from GIPJAZES Web 🚀");
        alert(`Successfully uploaded: ${selectedFile.name}`);
        setSelectedFile(null); // Reset after upload
        onClose();
      } catch (e: any) {
        alert("Upload failed: " + e.message);
      }
    } else {
      alert("Please select a file first.");
    }
  };

  return (
    <div className="modal-overlay">
      <motion.div
        initial={{ opacity: 0, scale: 0.9, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.9, y: 20 }}
        className="modal-content"
      >
        <button className="modal-close" onClick={onClose}><X size={28} /></button>
        <h2 className="modal-title" style={{ fontSize: '1.8rem' }}>Upload Video</h2>
        <p className="modal-subtitle">Post a video to your account</p>

        {/* Hidden file input */}
        <input
          type="file"
          ref={fileInputRef}
          style={{ display: 'none' }}
          accept="video/mp4,video/webm"
          onChange={handleFileChange}
        />

        {!selectedFile ? (
          <div className="upload-area" onClick={handleSelectFileClick}>
            <UploadCloud size={64} style={{ color: 'var(--brand-primary)', margin: '0 auto 20px', display: 'block' }} />
            <h3 style={{ color: 'white', marginBottom: '10px' }}>Select video to upload</h3>
            <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>Or drag and drop a file</p>
            <div style={{ marginTop: '20px', fontSize: '0.85rem', color: 'rgba(255,255,255,0.4)' }}>
              <p>MP4 or WebM</p>
              <p>720x1280 resolution or higher</p>
              <p>Up to 10 minutes</p>
              <p>Less than 2 GB</p>
            </div>
          </div>
        ) : (
          <div className="upload-area" style={{ borderColor: 'var(--brand-accent)', background: 'rgba(16, 185, 129, 0.05)' }}>
            <Film size={64} style={{ color: 'var(--brand-accent)', margin: '0 auto 20px', display: 'block' }} />
            <h3 style={{ color: 'white', marginBottom: '10px' }}>File Ready</h3>
            <p style={{ color: 'var(--text-muted)', fontSize: '1rem', wordBreak: 'break-all' }}>{selectedFile.name}</p>
            <div style={{ marginTop: '20px', fontSize: '0.85rem', color: 'rgba(255,255,255,0.4)' }}>
              <p>{(selectedFile.size / (1024 * 1024)).toFixed(2)} MB</p>
            </div>
          </div>
        )}

        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.95 }}
          className="submit-btn"
          style={{ marginTop: '30px', background: selectedFile ? 'var(--brand-accent)' : 'var(--brand-primary)' }}
          onClick={selectedFile ? handleUploadSubmit : handleSelectFileClick}
        >
          {selectedFile ? 'Start Upload' : 'Select File'}
        </motion.button>

      </motion.div>
    </div>
  );
};


interface VideoData {
  id: number;
  url: string;
  username: string;
  description: string;
  initialLikes: number;
  comments: number;
  shares: number;
}

const VideoPost = ({ data }: { data: VideoData }) => {
  const ref = useRef<HTMLDivElement>(null);
  const isInView = useInView(ref, { amount: 0.6 });
  const [isPlaying, setIsPlaying] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);

  const [isLiked, setIsLiked] = useState(false);
  const [likeCount, setLikeCount] = useState(data.initialLikes);
  const [isFollowing, setIsFollowing] = useState(false);
  const [isSaved, setIsSaved] = useState(false);
  const [showHeart, setShowHeart] = useState(false);

  const [commentCount, setCommentCount] = useState(data.comments);
  const [shareCount, setShareCount] = useState(data.shares);

  const formatCount = (num: number) => {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
    return num.toString();
  };

  if (videoRef.current) {
    if (isInView && !isPlaying) {
      videoRef.current.play().catch(() => console.log("Autoplay blocked"));
      setIsPlaying(true);
    } else if (!isInView && isPlaying) {
      videoRef.current.pause();
      setIsPlaying(false);
    }
  }

  const togglePlay = () => {
    if (videoRef.current) {
      if (isPlaying) {
        videoRef.current.pause();
      } else {
        videoRef.current.play();
      }
      setIsPlaying(!isPlaying);
    }
  };

  const handleLike = () => {
    setIsLiked(!isLiked);
    setLikeCount(isLiked ? likeCount - 1 : likeCount + 1);
  };

  const handleDoubleTap = () => {
    if (!isLiked) {
      setIsLiked(true);
      setLikeCount(likeCount + 1);
    }
    setShowHeart(true);
    setTimeout(() => setShowHeart(false), 800);
  };

  const handleComment = () => {
    setCommentCount(commentCount + 1);
    alert("Comment Panel Simulation: Opened!");
  };

  const handleShare = () => {
    setShareCount(shareCount + 1);
    alert("Share Simulation: Link copied to clipboard!");
  };

  return (
    <div className="video-container" ref={ref}>
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        whileInView={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.6, ease: "circOut" }}
        viewport={{ once: false, amount: 0.5 }}
        className="video-player"
      >
        <video
          ref={videoRef}
          src={data.url}
          style={{ width: '100%', height: '100%', objectFit: 'cover', cursor: 'pointer' }}
          onClick={togglePlay}
          onDoubleClick={handleDoubleTap}
          loop
          muted={false}
        />

        <div className="video-overlay" />

        <AnimatePresence>
          {showHeart && (
            <motion.div
              initial={{ opacity: 0, scale: 0.5, y: 0 }}
              animate={{ opacity: 1, scale: 1.5, y: -50 }}
              exit={{ opacity: 0, scale: 2 }}
              transition={{ duration: 0.4, ease: 'easeOut' }}
              style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', zIndex: 60, pointerEvents: 'none' }}
            >
              <Heart size={120} fill="var(--brand-danger)" stroke="none" />
            </motion.div>
          )}
        </AnimatePresence>

        <AnimatePresence>
          {!isPlaying && (
            <motion.div
              initial={{ opacity: 0, scale: 0.5 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 1.5 }}
              transition={{ duration: 0.2 }}
              className="play-indicator"
            >
              <Play size={80} fill="rgba(255,255,255,0.8)" />
            </motion.div>
          )}
        </AnimatePresence>

        <div className="video-info">
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            whileInView={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.2 }}
            className="username"
          >
            {data.username}
            <button
              className={`follow-btn ${isFollowing ? 'following' : ''}`}
              onClick={() => setIsFollowing(!isFollowing)}
            >
              {isFollowing ? 'Following' : 'Follow'}
            </button>
          </motion.div>
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            whileInView={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.3 }}
            className="description"
          >
            {data.description}
          </motion.div>
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            transition={{ delay: 0.4 }}
            style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '14px', fontSize: '0.9rem', color: 'var(--text-main)', opacity: 0.8 }}
          >
            <Music size={16} />
            <div style={{ overflow: 'hidden', whiteSpace: 'nowrap', width: '150px' }}>
              <motion.div
                animate={{ x: [-150, 150] }}
                transition={{ repeat: Infinity, duration: 8, ease: "linear" }}
              >
                Original Sound - GIPJAZES
              </motion.div>
            </div>
          </motion.div>
        </div>

        <div className="action-buttons">
          <motion.button
            whileTap={{ scale: 0.8 }}
            className={`action-btn ${isLiked ? 'liked' : ''}`}
            onClick={handleLike}
          >
            <div className="btn-icon-wrapper">
              <Heart size={26} fill={isLiked ? "currentColor" : "none"} strokeWidth={isLiked ? 0 : 2} />
            </div>
            <span style={{ fontWeight: 600, fontSize: '0.85rem' }}>{formatCount(likeCount)}</span>
          </motion.button>

          <motion.button
            whileHover={{ y: -5 }}
            whileTap={{ scale: 0.8 }}
            className="action-btn"
            onClick={handleComment}
          >
            <div className="btn-icon-wrapper"><MessageCircle size={26} strokeWidth={2} /></div>
            <span style={{ fontWeight: 600, fontSize: '0.85rem' }}>{formatCount(commentCount)}</span>
          </motion.button>

          <motion.button
            whileHover={{ y: -5 }}
            whileTap={{ scale: 0.8 }}
            className="action-btn"
            onClick={() => setIsSaved(!isSaved)}
          >
            <div className="btn-icon-wrapper">
              <Bookmark size={26} strokeWidth={2} fill={isSaved ? "var(--brand-primary)" : "none"} color={isSaved ? "var(--brand-primary)" : "white"} />
            </div>
            <span style={{ fontWeight: 600, fontSize: '0.85rem' }}>Save</span>
          </motion.button>

          <motion.button
            whileHover={{ y: -5 }}
            whileTap={{ scale: 0.8 }}
            className="action-btn"
            onClick={handleShare}
          >
            <div className="btn-icon-wrapper"><Share2 size={26} strokeWidth={2} /></div>
            <span style={{ fontWeight: 600, fontSize: '0.85rem' }}>{formatCount(shareCount)}</span>
          </motion.button>
        </div>
      </motion.div>
    </div>
  );
};

const ExploreContent = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [isSearching, setIsSearching] = useState(false);

  const handleSearch = async () => {
    if (!searchQuery.trim()) return;
    setIsSearching(true);
    try {
      const data = await GIPJAZES_API.searchVideos(searchQuery);
      if (data && data.videos) {
        setSearchResults(data.videos);
      } else {
        setSearchResults([]);
      }
    } catch (e) {
      console.error(e);
      setSearchResults([]);
    } finally {
      setIsSearching(false);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      style={{ color: 'white', padding: '10vh 5%', width: '100%', maxWidth: '1200px', margin: '0 auto' }}
    >
      <div style={{ textAlign: 'center', marginBottom: '60px' }}>
        <Compass size={48} color="var(--brand-primary)" style={{ margin: '0 auto 20px', display: 'block' }} />
        <h2 style={{ fontSize: '2.5rem', marginBottom: '15px' }}>Explore Trends</h2>
        <p style={{ color: 'var(--text-muted)', fontSize: '1.2rem' }}>Discover new creators and viral content across GIPJAZES.</p>
      </div>

      <div className="search-bar-container" style={{ position: 'relative', maxWidth: '600px', margin: '0 auto 50px' }}>
        <input
          type="text"
          className="search-input"
          placeholder="Search for videos or creators..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
          style={{ width: '100%', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '30px', padding: '18px 60px 18px 25px', color: 'white', fontSize: '1.1rem', outline: 'none' }}
        />
        <button onClick={handleSearch} style={{ position: 'absolute', right: '10px', top: '50%', transform: 'translateY(-50%)', background: 'var(--brand-primary)', color: 'black', border: 'none', borderRadius: '50%', width: '45px', height: '45px', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          <Search size={22} />
        </button>
      </div>

      {isSearching ? (
        <div style={{ textAlign: 'center', marginTop: '40px' }}>
          <div className="loader" style={{ width: '40px', height: '40px', border: '3px solid rgba(255,0,229,0.1)', borderTopColor: 'var(--brand-primary)', borderRadius: '50%', animation: 'spin 1s linear infinite', margin: '0 auto' }} />
        </div>
      ) : searchResults.length > 0 ? (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '15px' }}>
          {searchResults.map((vid: any) => (
            <motion.div
              key={vid.id}
              whileHover={{ scale: 1.05 }}
              style={{ background: '#000', aspectRatio: '9/16', borderRadius: '15px', overflow: 'hidden', position: 'relative', cursor: 'pointer', border: '1px solid rgba(255,255,255,0.1)' }}
            >
              <video src={vid.url} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              <div style={{ position: 'absolute', bottom: '0', left: '0', right: '0', padding: '10px', background: 'linear-gradient(transparent, rgba(0,0,0,0.8))' }}>
                <p style={{ fontSize: '0.85rem', fontWeight: 600 }}>@{vid.creator?.username || 'user'}</p>
              </div>
            </motion.div>
          ))}
        </div>
      ) : searchQuery && !isSearching ? (
        <p style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No results found for "{searchQuery}"</p>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: '20px', opacity: 0.5 }}>
          {[1, 2, 3, 4, 5, 6].map(i => (
            <div key={i} style={{ aspectRatio: '9/16', background: 'rgba(255,225,255,0.03)', borderRadius: '15px', border: '1px dashed rgba(255,255,255,0.05)' }} />
          ))}
        </div>
      )}
    </motion.div>
  );
};

function App() {
  const [activeTab, setActiveTab] = useState('For You');
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);
  const [sessionToken, setSessionToken] = useState(localStorage.getItem('gipjazes_token') || '');

  const [videoFeed, setVideoFeed] = useState<any[]>([]);

  const handleAuthSuccess = (token: string) => {
    localStorage.setItem('gipjazes_token', token);
    setSessionToken(token);
  };

  useEffect(() => {
    const fetchFeed = async () => {
      try {
        const feedData = await GIPJAZES_API.getFeed(undefined, activeTab);
        if (feedData && feedData.videos) {
          const mappedFeed = feedData.videos.map((vid: any) => ({
            id: vid.id,
            url: vid.url,
            username: vid.creator ? `@${vid.creator.username}` : `@${vid.creatorId.substring(0, 8)}`,
            description: vid.description,
            initialLikes: vid.likeCount || 0,
            comments: vid.commentCount || 0,
            shares: vid.shareCount || 0
          }));
          setVideoFeed(mappedFeed.length > 0 ? mappedFeed : []);
        } else {
          setVideoFeed([]);
        }
      } catch (e) {
        console.error("Could not fetch feed.", e);
        setVideoFeed([]);
      }
    };
    if (activeTab === 'For You' || categories.includes(activeTab)) {
      fetchFeed();
    }
  }, [activeTab]);

  const renderContent = () => {
    switch (activeTab) {
      case 'For You':
        return videoFeed.map((post) => (
          <VideoPost key={post.id} data={post} />
        ));
      case 'Explore':
        return (
          <ExploreContent />
        );
      case 'Comedy':
      case 'Music':
      case 'Gaming':
      case 'Tech':
      case 'Travel':
      case 'Food':
        return videoFeed.map((post) => (
          <VideoPost key={post.id} data={post} />
        ));
      case 'Live':
        return (
          <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} style={{ color: 'white', marginTop: '20vh', textAlign: 'center', width: '100%' }}>
            <Video size={64} color="var(--brand-danger)" style={{ margin: '0 auto 20px', display: 'block' }} />
            <h2 style={{ fontSize: '2.5rem', marginBottom: '15px' }}>Live Broadcasts</h2>
            <p style={{ color: 'var(--text-muted)', fontSize: '1.2rem' }}>No creators you follow are live right now.</p>
          </motion.div>
        );
      case 'Profile':
        return (
          <motion.div initial={{ opacity: 0, x: 50 }} animate={{ opacity: 1, x: 0 }} style={{ color: 'white', marginTop: '20vh', textAlign: 'center', width: '100%' }}>
            <User size={64} color="var(--brand-secondary)" style={{ margin: '0 auto 20px', display: 'block' }} />
            <h2 style={{ fontSize: '2.5rem', marginBottom: '15px' }}>GIPJAZES Profile</h2>
            <p style={{ color: 'var(--text-muted)', fontSize: '1.2rem' }}>Sign in to view your uploaded videos, likes, and followers.</p>
            <button className="upload-button" onClick={() => setIsAuthModalOpen(true)} style={{ margin: '40px auto 0', padding: '12px 30px' }}>Login / Register</button>
          </motion.div>
        );
      default:
        return null;
    }
  };

  return (
    <div className="app-container">
      <AnimatePresence>
        {isAuthModalOpen && <AuthModal isOpen={isAuthModalOpen} onClose={() => setIsAuthModalOpen(false)} onSuccess={handleAuthSuccess} />}
        {isUploadModalOpen && <UploadModal isOpen={isUploadModalOpen} onClose={() => setIsUploadModalOpen(false)} token={sessionToken} />}
      </AnimatePresence>

      <Sidebar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        onOpenUpload={() => setIsUploadModalOpen(true)}
      />
      <div className="main-feed" style={{ display: activeTab === 'For You' ? 'flex' : 'block' }}>
        {renderContent()}
      </div>
    </div>
  );
}

export default App;
