import { useState, useRef, useEffect } from 'react';
import { motion, useInView, AnimatePresence } from 'framer-motion';
import { Heart, MessageCircle, Share2, Compass, Home, User, PlusSquare, Play, Bookmark, X, Mail, Lock, UploadCloud, Key, Search, Menu, CheckCircle, Gift, Bell, Music, Video } from 'lucide-react';
import { GIPJAZES_API } from './lib/api';
import './index.css';
import logo from './assets/logo.png';

const categories = ["Comedy", "Music", "Tech", "Travel", "Food"];

// Removed mockFeed in favor of live DB connection

const SplashScreen = ({ onComplete }: { onComplete: () => void }) => {
  useEffect(() => {
    const timer = setTimeout(() => {
      onComplete();
    }, 2500);
    return () => clearTimeout(timer);
  }, [onComplete]);

  return (
    <motion.div
      initial={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 1 }}
      className="splash-screen"
    >
      <motion.div
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.8, ease: "easeOut" }}
        className="splash-logo-container"
      >
        <img src={logo} alt="GIPJAZES Logo" className="splash-logo" />
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.5, duration: 0.8 }}
        >
          <h1 className="splash-title">GIPJAZES V</h1>
          <p className="splash-tagline">Short Videos. Big Fun. Share & Connect</p>
        </motion.div>
      </motion.div>
    </motion.div>
  );
};

const Sidebar = ({
  activeTab,
  setActiveTab,
  onOpenUpload,
  isOpen,
  setIsOpen
}: {
  activeTab: string,
  setActiveTab: (tab: string) => void,
  onOpenUpload: () => void,
  isOpen: boolean,
  setIsOpen: (isOpen: boolean) => void
}) => {
  const navItems = [
    { name: 'For You', icon: Home },
    { name: 'Explore', icon: Compass },
    { name: 'Notifications', icon: Bell },
    { name: 'Profile', icon: User },
    { name: 'Wallet', icon: PlusSquare },
    { name: 'Live', icon: Video }
  ];

  const handleItemClick = (name: string) => {
    setActiveTab(name);
    if (window.innerWidth <= 768) {
      setIsOpen(false);
    }
  };

  return (
    <motion.div
      initial={{ x: -260 }}
      animate={{ x: isOpen ? 0 : -260 }}
      transition={{ type: "spring", stiffness: 300, damping: 30 }}
      className="sidebar"
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '40px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <img src={logo} alt="Logo" style={{ width: '45px', height: '45px', borderRadius: '12px' }} />
          <div className="brand-text" style={{ fontSize: '1.4rem', fontWeight: 800, color: 'var(--text-main)', letterSpacing: '0.5px' }}>
            GIPJAZES<span style={{ color: 'var(--brand-primary)' }}>.V</span>
          </div>
        </div>
        <button className="close-sidebar-btn" onClick={() => setIsOpen(false)}>
          <X size={24} />
        </button>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', flex: 1 }}>
        {navItems.map((item) => (
          <div
            key={item.name}
            className={`nav-item ${activeTab === item.name ? 'active' : ''}`}
            onClick={() => handleItemClick(item.name)}
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
              onClick={() => handleItemClick(cat)}
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
  const [isForgot, setIsForgot] = useState(false);
  const [email, setEmail] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [recoveryToken, setRecoveryToken] = useState('');
  const [newPassword, setNewPassword] = useState('');

  if (!isOpen) return null;

  const handleSubmit = async () => {
    try {
      if (isForgot) {
        if (recoveryToken) {
          await GIPJAZES_API.resetPassword(recoveryToken, newPassword);
          alert("Password reset successful! You can now log in.");
          setIsForgot(false);
          setRecoveryToken('');
        } else {
          const res = await GIPJAZES_API.forgotPassword(email);
          alert("Successful");
          setRecoveryToken(res.recovery_token);
        }
      } else if (isLogin) {
        const result = await GIPJAZES_API.login(email, password);
        onSuccess(result.token);
        onClose();
      } else {
        const result = await GIPJAZES_API.register(username, email, password);
        onSuccess(result.token);
        onClose();
      }
    } catch (e: any) {
      alert(`Error: ${e.message}`);
    }
  };

  return (
    <div className="modal-overlay">
      <motion.div
        initial={{ opacity: 0, scale: 0.9, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        className="modal-content"
      >
        <button className="modal-close" onClick={onClose}><X size={28} /></button>
        <h2 className="modal-title">{isForgot ? 'Recover Access' : isLogin ? 'Welcome Back' : 'Join GIPJAZES'}</h2>
        <p className="modal-subtitle">
          {isForgot ? 'Enter your email to reset your password' : isLogin ? 'Log in to continue your journey.' : 'Register to share your videos.'}
        </p>

        {!isForgot && !recoveryToken && (
           <>
            <div className="form-group">
              <div className="form-input-container">
                <Mail className="form-icon" size={20} />
                <input type="email" placeholder="Email Address" className="form-input" value={email} onChange={(e) => setEmail(e.target.value)} />
              </div>
            </div>
            {!isLogin && (
              <div className="form-group">
                <div className="form-input-container">
                  <User className="form-icon" size={20} />
                  <input type="text" placeholder="Username" className="form-input" value={username} onChange={(e) => setUsername(e.target.value)} />
                </div>
              </div>
            )}
            <div className="form-group">
              <div className="form-input-container">
                <Lock className="form-icon" size={20} />
                <input type={showPassword ? "text" : "password"} placeholder="Password" className="form-input" value={password} onChange={(e) => setPassword(e.target.value)} />
                <button type="button" onClick={() => setShowPassword(!showPassword)} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', paddingRight: '10px' }}>
                  {showPassword ? 'Hide' : 'Show'}
                </button>
              </div>
            </div>
          </>
        )}

        {isForgot && (
          <div className="form-group">
            <div className="form-input-container">
              {recoveryToken ? (
                <>
                  <Lock className="form-icon" size={20} />
                  <input type="password" placeholder="New Password" className="form-input" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} />
                </>
              ) : (
                <>
                  <Mail className="form-icon" size={20} />
                  <input type="email" placeholder="Registered Email" className="form-input" value={email} onChange={(e) => setEmail(e.target.value)} />
                </>
              )}
            </div>
          </div>
        )}

        <div className="key-btn-container" onClick={handleSubmit}>
          <div className="key-svg-wrapper">
            <Key size={34} color="var(--brand-primary)" strokeWidth={2.5} />
          </div>
          <div className="key-label">{isForgot ? (recoveryToken ? 'Set New Password' : 'Send Recovery') : isLogin ? 'Unlock GIPJAZES' : 'Initialize Access'}</div>
        </div>

        <div className="toggle-form" style={{ marginTop: '20px' }}>
          <span onClick={() => { setIsLogin(!isLogin); setIsForgot(false); }}>{isLogin ? 'Create Account' : 'Back to Login'}</span>
          {isLogin && <span style={{ marginLeft: '15px', color: 'var(--text-muted)' }} onClick={() => setIsForgot(!isForgot)}>{isForgot ? 'Back to Login' : 'Forgot Password?'}</span>}
        </div>
      </motion.div>
    </div>
  );
};

const UploadModal = ({ isOpen, onClose, token }: { isOpen: boolean, onClose: () => void, token: string }) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [description, setDescription] = useState("");
  const [hashtags, setHashtags] = useState("");

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
    if (!token) return alert("Please log in!");
    if (selectedFile) {
      try {
        const fullDesc = `${description} ${hashtags}`;
        await GIPJAZES_API.uploadVideo(selectedFile, token, fullDesc);
        alert(`Successfully uploaded!`);
        setSelectedFile(null);
        setDescription("");
        setHashtags("");
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
        className="modal-content"
      >
        <button className="modal-close" onClick={onClose}><X size={28} /></button>
        <h2 className="modal-title">Share Your Content</h2>
        <input type="file" ref={fileInputRef} onChange={handleFileChange} accept="video/*" style={{ display: 'none' }} />
        
        {!selectedFile ? (
          <div className="upload-area" onClick={handleSelectFileClick}>
            <UploadCloud size={64} style={{ color: 'var(--brand-primary)', margin: '0 auto 10px', display: 'block' }} />
            <p>Tap to select a video for GIPJAZES</p>
          </div>
        ) : (
          <div className="upload-form-preview">
            <p style={{ color: 'var(--brand-accent)', marginBottom: '15px' }}>✓ {selectedFile.name}</p>
            <textarea 
              className="form-input" 
              placeholder="What's this video about?" 
              value={description} 
              onChange={e => setDescription(e.target.value)} 
              style={{ height: '80px', marginBottom: '10px' }}
            />
            <input 
              type="text" 
              className="form-input" 
              placeholder="#hashtags #tiktok #viral" 
              value={hashtags} 
              onChange={e => setHashtags(e.target.value)} 
              style={{ marginBottom: '10px' }}
            />
            <div style={{ marginBottom: '20px' }}>
              <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '8px' }}>Select Template</p>
              <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '10px' }}>
                {['None', 'Retro', 'B&W', 'Vibrant', 'Cinematic'].map(t => (
                  <button
                    key={t}
                    onClick={() => setDescription(prev => `[Template: ${t}] ${prev}`)}
                    style={{ padding: '6px 12px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', color: 'white', fontSize: '0.75rem', cursor: 'pointer' }}
                  >
                    {t}
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}

        <motion.button
          whileTap={{ scale: 0.95 }}
          className="submit-btn"
          onClick={selectedFile ? handleUploadSubmit : handleSelectFileClick}
        >
          {selectedFile ? 'Post Now' : 'Select Video'}
        </motion.button>
      </motion.div>
    </div>
  );
};

const CommentModal = ({ 
  isOpen, 
  onClose, 
  videoId, 
  token,
  onCommentAdded
}: { 
  isOpen: boolean, 
  onClose: () => void, 
  videoId: string, 
  token: string,
  onCommentAdded: (count?: number) => void
}) => {
  const [comments, setComments] = useState<any[]>([]);
  const [newComment, setNewComment] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (isOpen && videoId) {
      loadComments();
    }
  }, [isOpen, videoId]);

  const loadComments = async () => {
    try {
      const data = await GIPJAZES_API.getComments(videoId.toString());
      setComments(data || []);
    } catch (e) {
      console.error(e);
    }
  };

  const handleSubmit = async () => {
    if (!token) {
      alert("Login to comment!");
      return;
    }
    if (!newComment.trim()) return;
    
    setIsLoading(true);
    try {
      const resp = await GIPJAZES_API.createComment(token, videoId.toString(), newComment);
      setNewComment("");
      await loadComments();
      if (resp.new_count !== undefined) {
        onCommentAdded(resp.new_count);
      } else {
        onCommentAdded();
      }
    } catch (e) {
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" style={{ zIndex: 1000 }}>
      <motion.div
        initial={{ opacity: 0, y: 100 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: 100 }}
        className="modal-content"
        style={{ maxHeight: '70vh', borderRadius: '20px 20px 0 0', marginTop: 'auto', display: 'flex', flexDirection: 'column' }}
      >
        <button className="modal-close" onClick={onClose}><X size={28} /></button>
        <h2 className="modal-title" style={{ fontSize: '1.4rem', borderBottom: '1px solid rgba(255,255,255,0.05)', paddingBottom: '15px' }}>
          Comments ({comments.length})
        </h2>

        <div style={{ flex: 1, overflowY: 'auto', padding: '20px 0', display: 'flex', flexDirection: 'column', gap: '20px', minHeight: '30vh' }}>
          {comments.length === 0 ? (
            <p style={{ textAlign: 'center', color: 'var(--text-muted)', marginTop: '40px' }}>No comments yet. Be the first!</p>
          ) : (
            comments.map((c, i) => (
              <div key={i} style={{ display: 'flex', gap: '12px' }}>
                <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: 'rgba(255,225,255,0.1)', flexShrink: 0 }} />
                <div>
                  <p style={{ fontSize: '0.85rem', color: 'var(--brand-primary)', marginBottom: '4px' }}>@{c.user_id?.substring(0, 8) || 'user'}</p>
                  <p style={{ fontSize: '0.95rem', color: 'white', lineHeight: 1.4 }}>{c.content}</p>
                </div>
              </div>
            ))
          )}
        </div>

        <div style={{ borderTop: '1px solid rgba(255,255,255,0.05)', padding: '20px 0 10px', display: 'flex', gap: '12px' }}>
          <input
            type="text"
            className="form-input"
            style={{ borderRadius: '12px', flex: 1 }}
            placeholder="Add a comment..."
            value={newComment}
            onChange={(e) => setNewComment(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSubmit()}
          />
          <motion.button
            whileTap={{ scale: 0.9 }}
            className="upload-button"
            style={{ width: 'auto', padding: '0 20px', borderRadius: '12px', height: '52px' }}
            onClick={handleSubmit}
            disabled={isLoading}
          >
            Post
          </motion.button>
        </div>
      </motion.div>
    </div>
  );
};


interface VideoData {
  id: string;
  url: string;
  username: string;
  description: string;
  initialLikes: number;
  comments: number;
  shares: number;
  isVerified?: boolean;
  creatorId: string;
}

const RewardBar = ({ isActive }: { isActive: boolean }) => {
  const [progress, setProgress] = useState(0);
  const [isRewarded, setIsRewarded] = useState(false);

  useEffect(() => {
    let interval: any;
    if (isActive && !isRewarded) {
      interval = setInterval(() => {
        setProgress(prev => {
          if (prev >= 100) {
            setIsRewarded(true);
            return 100;
          }
          return prev + 1; // 100 iterations of 100ms = 10s to earn reward
        });
      }, 100);
    } else if (!isActive) {
      // Don't reset, just pause
    }
    return () => clearInterval(interval);
  }, [isActive, isRewarded]);

  return (
    <div className="reward-container" style={{ position: 'absolute', bottom: '0', left: '0', right: '0', height: '4px', background: 'rgba(255,255,255,0.1)', overflow: 'hidden' }}>
      <motion.div 
        initial={{ width: 0 }} 
        animate={{ width: `${progress}%` }} 
        style={{ height: '100%', background: isRewarded ? 'var(--brand-accent)' : 'linear-gradient(90deg, var(--brand-primary), var(--brand-secondary))', boxShadow: isRewarded ? '0 0 10px var(--brand-accent)' : 'none' }}
      />
      {isRewarded && (
        <motion.div 
           initial={{ opacity: 0, scale: 0.5, y: 10 }}
           animate={{ opacity: 1, scale: 1, y: -40 }}
           style={{ position: 'absolute', right: '20px', background: 'var(--brand-accent)', color: 'black', padding: '4px 10px', borderRadius: '12px', fontSize: '0.75rem', fontWeight: 800 }}
        >
          +5 JAZE
        </motion.div>
      )}
    </div>
  );
};
const PollOverlay = ({ description }: { description: string }) => {
  const [voted, setVoted] = useState<number | null>(null);
  const pollMatch = description.match(/(.+)\? \[(.+)\|(.+)\]/);
  if (!pollMatch) return null;
  const question = pollMatch[1] + "?";
  const options = [pollMatch[2], pollMatch[3]];
  return (
    <motion.div 
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      style={{ position: 'absolute', left: '20px', bottom: '150px', width: '220px', background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(10px)', border: '1px solid var(--glass-border)', borderRadius: '16px', padding: '15px', zIndex: 70 }}
    >
      <p style={{ fontSize: '0.85rem', fontWeight: 700, marginBottom: '10px' }}>{question}</p>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
        {options.map((opt, i) => (
          <button
            key={i}
            onClick={() => setVoted(i)}
            style={{
              width: '100%',
              padding: '8px',
              borderRadius: '8px',
              border: '1px solid rgba(255,255,255,0.1)',
              background: voted === i ? 'var(--brand-primary)' : 'rgba(255,255,255,0.1)',
              color: voted === i ? 'black' : 'white',
              fontSize: '0.8rem',
              fontWeight: 600,
              cursor: 'pointer',
              position: 'relative',
              overflow: 'hidden'
            }}
          >
            {voted !== null && (
              <motion.div 
                initial={{ width: 0 }}
                animate={{ width: i === 0 ? '65%' : '35%' }}
                style={{ position: 'absolute', top: 0, left: 0, bottom: 0, background: 'rgba(255,255,255,0.2)', zIndex: -1 }}
              />
            )}
            <span style={{ position: 'relative', zIndex: 1 }}>{opt} {voted !== null && (i === 0 ? '65%' : '35%')}</span>
          </button>
        ))}
      </div>
    </motion.div>
  );
};

const VideoPost = ({ data, token }: { data: VideoData, token: string }) => {
  const ref = useRef<HTMLDivElement>(null);
  const isInView = useInView(ref, { amount: 0.6 });
  const [isPlaying, setIsPlaying] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);

  const [isLiked, setIsLiked] = useState(false);
  const [likeCount, setLikeCount] = useState(data.initialLikes);
  const [isFollowing, setIsFollowing] = useState(false);
  const [isSaved, setIsSaved] = useState(false);
  const [showHeart, setShowHeart] = useState(false);
  const [isCommentModalOpen, setIsCommentModalOpen] = useState(false);

  const [commentCount, setCommentCount] = useState(data.comments);
  const [shareCount, setShareCount] = useState(data.shares);

  const getTemplateStyle = (desc: string) => {
    if (desc.includes('[Template: Retro]')) return { filter: 'sepia(0.6) hue-rotate(-30deg) contrast(1.2)' };
    if (desc.includes('[Template: B&W]')) return { filter: 'grayscale(1) contrast(1.2)' };
    if (desc.includes('[Template: Vibrant]')) return { filter: 'saturate(1.5) contrast(1.1)' };
    if (desc.includes('[Template: Cinematic]')) return { filter: 'brightness(0.9) contrast(1.3) saturate(0.8)' };
    return {};
  };

  const formatCount = (num: number) => {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
    return num.toString();
  };

  useEffect(() => {
    if (videoRef.current) {
      if (isInView) {
        videoRef.current.play().catch(() => {
          console.log("Autoplay blocked");
          setIsPlaying(false);
        });
        GIPJAZES_API.incrementView(data.id.toString());
        setIsPlaying(true);
      } else {
        videoRef.current.pause();
        setIsPlaying(false);
      }
    }
  }, [isInView, data.id]);

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

  const [isMuted, setIsMuted] = useState(true);
  const toggleMute = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (videoRef.current) {
      videoRef.current.muted = !isMuted;
      setIsMuted(!isMuted);
    }
  };

  const handleLike = async () => {
    if (!token) {
      alert("Login to like!");
      return;
    }
    const wasLiked = isLiked;
    setIsLiked(!isLiked);
    setLikeCount(wasLiked ? likeCount - 1 : likeCount + 1);
    
    try {
      const resp = await GIPJAZES_API.toggleLike(token, data.id.toString());
      if (resp.new_count !== undefined) {
        setLikeCount(resp.new_count);
        setIsLiked(resp.is_liked);
      }
    } catch (e) {
      // Revert if failed
      setIsLiked(wasLiked);
      setLikeCount(likeCount);
    }
  };

  const handleDoubleTap = () => {
    if (!isLiked) {
      handleLike();
    }
    setShowHeart(true);
    setTimeout(() => setShowHeart(false), 800);
  };

  const handleComment = () => {
    setIsCommentModalOpen(true);
  };

  const handleShare = async () => {
    setShareCount(shareCount + 1);
    const shareData = {
      title: 'GIPJAZES V',
      text: `Check out this video by ${data.username}`,
      url: window.location.origin + "?video=" + data.id
    };

    if (navigator.share) {
      try {
        await navigator.share(shareData);
      } catch (err) {
        navigator.clipboard.writeText(shareData.url);
        alert("Link copied to clipboard!");
      }
    } else {
      navigator.clipboard.writeText(shareData.url);
      alert("Link copied to clipboard!");
    }
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
          style={{ width: '100%', height: '100%', objectFit: 'cover', cursor: 'pointer', ...getTemplateStyle(data.description) }}
          onClick={togglePlay}
          onDoubleClick={handleDoubleTap}
          loop
          playsInline
          autoPlay
          muted={isMuted}
        />

        <div className="video-overlay" />

        {isMuted && isPlaying && (
          <motion.div 
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            onClick={toggleMute}
            style={{ position: 'absolute', top: '20px', right: '20px', background: 'rgba(0,0,0,0.6)', padding: '8px 12px', borderRadius: '20px', fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', zIndex: 100, border: '1px solid rgba(255,255,255,0.2)' }}
          >
            <Music size={14} /> Tap to Unmute
          </motion.div>
        )}

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

        {/* Reward Progress System */}
        <RewardBar isActive={isInView && isPlaying} />

        {/* Interactive Polls */}
        <PollOverlay description={data.description} />

        <div className="video-info">
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            whileInView={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.2 }}
            className="username"
          >
            {data.username}
            {data.isVerified && <CheckCircle size={16} fill="var(--brand-accent)" color="black" style={{ marginLeft: '4px' }} />}
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

          <motion.button
            whileHover={{ y: -5 }}
            whileTap={{ scale: 0.8 }}
            className="action-btn"
            onClick={async () => {
              if(!token) return alert("Login to repost!");
              try {
                await GIPJAZES_API.repost(token, data.id.toString());
                alert("Successful");
              } catch(e) { alert("Repost failed"); }
            }}
          >
            <div className="btn-icon-wrapper"><PlusSquare size={26} strokeWidth={2} color="var(--brand-accent)" /></div>
            <span style={{ fontWeight: 600, fontSize: '0.75rem' }}>Repost</span>
          </motion.button>

          <motion.button
            whileHover={{ y: -5 }}
            whileTap={{ scale: 0.8 }}
            className="action-btn"
            onClick={async () => {
              try {
                const response = await fetch(data.url);
                const blob = await response.blob();
                const url = window.URL.createObjectURL(blob);
                const link = document.createElement('a');
                link.href = url;
                link.download = `gipjazes_video_${data.id}.mp4`;
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                window.URL.revokeObjectURL(url);
              } catch (e) {
                alert("Download failed. Try long-pressing the video.");
              }
            }}
          >
            <div className="btn-icon-wrapper"><UploadCloud size={26} strokeWidth={2} style={{ transform: 'rotate(180deg)' }} /></div>
            <span style={{ fontWeight: 600, fontSize: '0.75rem' }}>Save</span>
          </motion.button>

          <motion.button
            whileHover={{ y: -5 }}
            whileTap={{ scale: 0.8 }}
            className="action-btn"
            onClick={async () => {
              if(!token) return alert("Login to gift!");
              const amt = prompt("Enter gift amount (tokens):", "10");
              if(amt) {
                 try {
                   await GIPJAZES_API.sendGift(token, data.creatorId, parseInt(amt));
                   alert("Successful");
                 } catch(e:any) { alert(e.message); }
              }
            }}
          >
            <div className="btn-icon-wrapper"><Gift size={26} strokeWidth={2} color="var(--brand-primary)" /></div>
            <span style={{ fontWeight: 600, fontSize: '0.75rem' }}>Gift</span>
          </motion.button>
        </div>
      </motion.div>

      <CommentModal 
        isOpen={isCommentModalOpen} 
        onClose={() => setIsCommentModalOpen(false)} 
        videoId={data.id.toString()} 
        token={token}
        onCommentAdded={(count?: number) => setCommentCount(count !== undefined ? count : commentCount + 1)}
      />
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
              <video src={vid.video_url || vid.videoUrl || vid.url} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              <div style={{ position: 'absolute', bottom: '0', left: '0', right: '0', padding: '10px', background: 'linear-gradient(transparent, rgba(0,0,0,0.8))' }}>
                <p style={{ fontSize: '0.85rem', fontWeight: 600 }}>@{vid.creator?.username || 'user'}</p>
              </div>
            </motion.div>
          ))}
        </div>
      ) : searchQuery && !isSearching ? (
        <p style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No results found for "{searchQuery}"</p>
      ) : (
        <>
          <h3 style={{ marginBottom: '20px', fontSize: '1.2rem', opacity: 0.8 }}>Featured Creators</h3>
          <div style={{ display: 'flex', gap: '15px', overflowX: 'auto', paddingBottom: '30px', marginBottom: '30px' }}>
            {['NeonNova', 'PixelPioneer', 'DreamDrifter', 'CosmoCat', 'VibeVoyager'].map(user => (
              <div key={user} style={{ textAlign: 'center', minWidth: '100px' }}>
                <div style={{ width: '80px', height: '80px', borderRadius: '50%', background: 'linear-gradient(45deg, var(--brand-secondary), var(--brand-accent))', margin: '0 auto 10px', border: '2px solid var(--brand-primary)', padding: '3px' }}>
                   <div style={{ width: '100%', height: '100%', borderRadius: '50%', background: '#000', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <User size={30} />
                   </div>
                </div>
                <p style={{ fontSize: '0.8rem', fontWeight: 600 }}>@{user}</p>
              </div>
            ))}
          </div>
          <h3 style={{ marginBottom: '20px', fontSize: '1.2rem', opacity: 0.8 }}>Trending Now</h3>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: '20px' }}>
            {[1, 2, 3, 4, 5, 6].map(i => (
              <div key={i} style={{ aspectRatio: '9/16', background: 'rgba(255,225,255,0.03)', borderRadius: '15px', border: '1px dashed rgba(255,255,255,0.05)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                 <Play size={40} style={{ opacity: 0.1 }} />
              </div>
            ))}
          </div>
        </>
      )}
    </motion.div>
  );
};

const ProfileContent = ({ token, onLogout }: { token: string, onLogout: () => void }) => {
  const [profileData, setProfileData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editData, setEditData] = useState({ username: '', display_name: '', bio: '', avatar_url: '' });
  const [selectedVideo, setSelectedVideo] = useState<any>(null);

  const fetchProfile = async () => {
    if (!token) return;
    try {
      const data = await GIPJAZES_API.getProfile(token);
      setProfileData(data);
      setEditData({
        username: data.user.username,
        display_name: data.user.display_name,
        bio: data.user?.bio || data.bio || '',
        avatar_url: data.user?.avatar_url || ''
      });
    } catch (e) {
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchProfile();
  }, [token]);

  const handleUpdate = async () => {
    try {
      await GIPJAZES_API.updateProfile(token, editData);
      alert("Successful");
      setIsEditing(false);
      fetchProfile();
    } catch (e) {
      alert("Update failed");
    }
  };

  const handleDelete = async () => {
    if (window.confirm("Are you SURE you want to delete your account? This is PERMANENT.")) {
      try {
        await GIPJAZES_API.deleteAccount(token);
        alert("Account deleted.");
        onLogout();
      } catch (e) { alert("Deletion failed"); }
    }
  };

  if (isLoading) return <div className="loader" style={{ margin: '100px auto' }} />;
  
  if (!profileData) return (
    <div style={{ color: 'white', textAlign: 'center', marginTop: '100px' }}>
      <User size={64} color="var(--brand-secondary)" style={{ margin: '0 auto 20px', display: 'block' }} />
      <h2 style={{ fontSize: '2.5rem', marginBottom: '15px' }}>GIPJAZES Profile</h2>
      <p style={{ color: 'var(--text-muted)', fontSize: '1.2rem' }}>Sign in to see your growth.</p>
    </div>
  );

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="profile-tab-content"
      style={{ color: 'white', padding: '10vh 5%', width: '100%', maxWidth: '800px', margin: '0 auto' }}
    >
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: '40px' }}>
        <div style={{ position: 'relative' }}>
          <div 
            className="profile-avatar-clickable"
            onClick={() => {
              const input = document.createElement('input');
              input.type = 'file';
              input.accept = 'image/*';
              input.onchange = async (e: any) => {
                const file = e.target.files[0];
                if (file) {
                  try {
                    const res = await GIPJAZES_API.uploadAvatar(file, token);
                    await GIPJAZES_API.updateProfile(token, { 
                      avatar_url: res.avatar_url,
                      username: profileData.user.username,
                      display_name: profileData.user.display_name,
                      bio: profileData.user?.bio || profileData.bio || ''
                    });
                    alert("Profile picture updated!");
                    fetchProfile();
                  } catch (err) { alert("Upload failed: " + (err as any).message); }
                }
              };
              input.click();
            }}
            style={{ width: '120px', height: '120px', borderRadius: '50%', background: 'linear-gradient(45deg, var(--brand-primary), var(--brand-secondary))', marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '3rem', fontWeight: 800, overflow: 'hidden', cursor: 'pointer', border: '4px solid var(--brand-primary)', boxShadow: '0 0 30px rgba(255, 0, 229, 0.3)' }}
          >
            {profileData.user?.avatar_url ? <img src={profileData.user.avatar_url} style={{ width: '100%', height: '100%', objectFit: 'cover' }} /> : profileData.user?.username?.[0]?.toUpperCase()}
            <div className="profile-upload-hint">
              <PlusSquare size={20} />
            </div>
          </div>
        </div>
        <h2 style={{ fontSize: '2rem', marginBottom: '4px' }}>@{profileData.user?.username}</h2>
        <p style={{ color: 'var(--text-muted)', marginBottom: '20px' }}>{profileData.user?.display_name}</p>
        
        <div style={{ display: 'flex', gap: '20px', marginBottom: '30px' }}>
          <div style={{ textAlign: 'center' }}><p style={{ fontWeight: 800, fontSize: '1.2rem' }}>{profileData.following || 0}</p><p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>Following</p></div>
          <div style={{ textAlign: 'center' }}><p style={{ fontWeight: 800, fontSize: '1.2rem' }}>{profileData.followers || 0}</p><p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>Followers</p></div>
          <div style={{ textAlign: 'center' }}><p style={{ fontWeight: 800, fontSize: '1.2rem' }}>{profileData.total_likes || 0}</p><p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>Likes</p></div>
        </div>

        <p style={{ textAlign: 'center', maxWidth: '500px', lineHeight: 1.6, color: 'rgba(255,255,255,0.8)', marginBottom: '20px' }}>
          {profileData.user?.bio || profileData.bio || "No bio yet."}
        </p>

        <div style={{ display: 'flex', gap: '10px' }}>
          <button onClick={() => setIsEditing(true)} style={{ background: 'rgba(255,255,255,0.1)', border: 'none', color: 'white', padding: '10px 20px', borderRadius: '8px', cursor: 'pointer' }}>Edit Profile</button>
          <button onClick={onLogout} style={{ background: 'rgba(255,0,0,0.1)', border: 'none', color: 'red', padding: '10px 20px', borderRadius: '8px', cursor: 'pointer' }}>Logout</button>
        </div>
      </div>

      {isEditing && (
        <div className="modal-overlay" style={{ zIndex: 2000 }}>
          <div className="modal-content" style={{ maxWidth: '400px' }}>
             <button className="modal-close" onClick={() => setIsEditing(false)}><X size={28} /></button>
             <h2 className="modal-title">Edit Profile</h2>
             <input type="text" className="form-input" placeholder="Display Name" value={editData.display_name} onChange={e => setEditData({...editData, display_name: e.target.value})} style={{ marginBottom: '10px' }} />
             <input type="text" className="form-input" placeholder="Username" value={editData.username} onChange={e => setEditData({...editData, username: e.target.value})} style={{ marginBottom: '10px' }} />
             <textarea className="form-input" placeholder="Bio" value={editData.bio} onChange={e => setEditData({...editData, bio: e.target.value})} style={{ marginBottom: '10px', height: '100px' }} />
             <input type="text" className="form-input" placeholder="Avatar URL" value={editData.avatar_url} onChange={e => setEditData({...editData, avatar_url: e.target.value})} style={{ marginBottom: '20px' }} />
             <button className="submit-btn" onClick={handleUpdate}>Save Changes</button>
             <button onClick={handleDelete} style={{ marginTop: '20px', color: 'red', background: 'none', border: 'none', cursor: 'pointer', width: '100%' }}>Delete Account</button>
          </div>
        </div>
      )}

      <div style={{ borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '30px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '4px' }}>
          {profileData.videos?.map((vid: any) => (
             <div 
               key={vid.id} 
               onClick={() => setSelectedVideo({
                 id: vid.id,
                 url: vid.video_url || vid.videoUrl || vid.url,
                 username: `@${profileData.user.username}`,
                 description: vid.description || "",
                 initialLikes: vid.like_count || vid.likeCount || 0,
                 comments: vid.comment_count || vid.commentCount || 0,
                 shares: vid.share_count || vid.shareCount || 0,
                 creatorId: profileData.user.id,
                 isVerified: profileData.user.is_verified || false
               })}
               style={{ aspectRatio: '9/16', background: '#000', borderRadius: '4px', overflow: 'hidden', position: 'relative', cursor: 'pointer' }}
             >
                 <video src={vid.video_url || vid.videoUrl || vid.url} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
             </div>
          ))}
        </div>
      </div>

      {selectedVideo && (
        <div className="modal-overlay" style={{ zIndex: 3000, padding: 0 }}>
          <button 
            style={{ position: 'absolute', top: '20px', left: '20px', zIndex: 3001, background: 'rgba(0,0,0,0.5)', borderRadius: '50%', color: 'white', border: 'none', width: '45px', height: '45px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }} 
            onClick={() => setSelectedVideo(null)}
          >
            <X size={28} />
          </button>
          <div style={{ width: '100vw', height: '100vh', display: 'flex', justifyContent: 'center', alignItems: 'center', background: 'black' }}>
             <div style={{ height: '100%', maxWidth: '500px', width: '100%', position: 'relative' }}>
                <VideoPost data={selectedVideo} token={token} />
             </div>
          </div>
        </div>
      )}
    </motion.div>
  );
};

const LiveTab = ({ token }: { token: string }) => {
  const [streams, setStreams] = useState<any[]>([]);
  const [isStarting, setIsStarting] = useState(false);

  useEffect(() => {
    fetchStreams();
  }, []);

  const fetchStreams = async () => {
    try {
      const data = await GIPJAZES_API.getLiveBroadcasts();
      setStreams(data || []);
    } catch (e) {}
  };

  const handleStartLive = async () => {
    if (!token) return alert("Login to go live!");
    const title = prompt("Enter broadcast title:", "My Live Session");
    if (!title) return;
    setIsStarting(true);
    try {
      await GIPJAZES_API.startLive(token, title);
      alert("Broadcast started! (Simulation: In a real app, your camera would turn on now)");
      fetchStreams();
    } catch (e) {
      alert("Could not start broadcast");
    } finally {
      setIsStarting(false);
    }
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} style={{ color: 'white', padding: '10vh 5%', width: '100%', maxWidth: '800px', margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '40px' }}>
        <h2 style={{ fontSize: '2rem' }}><Video size={32} color="var(--brand-danger)" style={{ verticalAlign: 'middle', marginRight: '10px' }} /> Live Now</h2>
        <button 
          className="upload-button" 
          style={{ width: 'auto', padding: '10px 25px', opacity: isStarting ? 0.7 : 1 }} 
          onClick={handleStartLive} 
          disabled={isStarting}
        >
          {isStarting ? 'Starting...' : 'Go Live'}
        </button>
      </div>

      {streams.length === 0 ? (
        <div style={{ textAlign: 'center', marginTop: '10vh', opacity: 0.5 }}>
          <Compass size={64} style={{ marginBottom: '20px' }} />
          <p>No active broadcasts at the moment.</p>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: '20px' }}>
          {streams.map((stream: any) => (
            <div key={stream.id} style={{ background: 'rgba(255,255,255,0.05)', borderRadius: '15px', padding: '20px', border: '1px solid rgba(255,0,0,0.2)' }}>
              <div style={{ display: 'flex', gap: '10px', alignItems: 'center', marginBottom: '15px' }}>
                <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: 'red', animation: 'pulse 1s infinite' }} />
                <span style={{ fontSize: '0.8rem', fontWeight: 800, color: 'red', textTransform: 'uppercase' }}>Live</span>
                <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginLeft: 'auto' }}>{stream.views} watching</span>
              </div>
              <h3 style={{ marginBottom: '5px' }}>{stream.title}</h3>
              <p style={{ color: 'var(--brand-primary)', fontSize: '0.9rem' }}>@{stream.username}</p>
            </div>
          ))}
        </div>
      )}
    </motion.div>
  );
};



function App() {
  const [showSplash, setShowSplash] = useState(true);
  const [activeTab, setActiveTab] = useState('For You');
  const [activeMood] = useState('Trending'); // Mood filter (setActiveMood removed as unused)
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);
  const [sessionToken, setSessionToken] = useState(localStorage.getItem('gipjazes_token') || '');
  const [isSidebarOpen, setIsSidebarOpen] = useState(window.innerWidth > 768);
  const [videoFeed, setVideoFeed] = useState<any[]>([]);

  useEffect(() => {
    const handleResize = () => {
      setIsSidebarOpen(window.innerWidth > 768);
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  const handleAuthSuccess = (token: string) => {
    localStorage.setItem('gipjazes_token', token);
    setSessionToken(token);
  };

  useEffect(() => {
    const fetchFeed = async () => {
      try {
        const feedData = await GIPJAZES_API.getFeed(undefined, activeTab === 'For You' ? (activeMood === 'Trending' ? 'For You' : activeMood) : activeTab);
        if (feedData && feedData.videos) {
          const mappedFeed = feedData.videos.map((vid: any) => ({
            id: vid.id,
            url: vid.video_url || vid.videoUrl || vid.url,
            username: vid.creator ? `@${vid.creator.username}` : `@${vid.creator_id ? vid.creator_id.substring(0, 8) : 'user'}`,
            creatorId: vid.creator_id || vid.creatorId,
            isVerified: vid.creator?.is_verified || vid.creator?.isVerified || false,
            description: vid.description,
            initialLikes: vid.like_count || vid.likeCount || 0,
            comments: vid.comment_count || vid.commentCount || 0,
            shares: vid.share_count || vid.shareCount || 0
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
  }, [activeTab, activeMood]);

  const NotificationsContent = () => {
    const [notifications, setNotifications] = useState<any[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
      const fetchNotifs = async () => {
        if (!sessionToken) return;
        try {
          const data = await GIPJAZES_API.getNotifications(sessionToken);
          setNotifications(data || []);
        } catch (e) { console.error(e); }
        finally { setIsLoading(false); }
      };
      fetchNotifs();
    }, []);

    if (isLoading) return <div className="loader" style={{ margin: '100px auto' }} />;

    return (
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} style={{ color: 'white', padding: '10vh 5%', width: '100%', maxWidth: '700px', margin: '0 auto' }}>
        <h2 style={{ fontSize: '2rem', marginBottom: '30px' }}><Bell size={32} style={{ verticalAlign: 'middle', marginRight: '10px' }} /> Activities</h2>
        {notifications.length === 0 ? (
          <p style={{ color: 'var(--text-muted)' }}>No new activities yet. Start interacting!</p>
        ) : (
          notifications.map((n: any) => (
            <div key={n.id} style={{ display: 'flex', gap: '15px', padding: '15px', background: 'rgba(255,255,255,0.03)', borderRadius: '12px', marginBottom: '10px', alignItems: 'center' }}>
               <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'linear-gradient(135deg, var(--brand-primary), var(--brand-secondary))' }} />
               <div style={{ flex: 1 }}>
                  <p style={{ fontWeight: 600 }}>{n.body}</p>
                  <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{new Date(n.created_at).toLocaleDateString()}</p>
               </div>
            </div>
          ))
        )}
      </motion.div>
    );
  };

  const WalletContent = ({ token }: { token: string }) => {
    const [balance, setBalance] = useState(0);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
      const fetchBalance = async () => {
        setIsLoading(true);
        try {
          const data = await GIPJAZES_API.getProfile(token);
          setBalance(data.user.balance || 0);
        } catch (e) {} finally { setIsLoading(false); }
      };
      fetchBalance();
    }, [token]);

    const handleClaim = () => {
      setBalance(prev => prev + 50);
      alert("Claimed 50 GAZ! 🎁 Visit daily for more.");
    };

    if (isLoading) return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
        <div className="loader" />
      </div>
    );

    return (
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} style={{ color: 'white', padding: '10vh 5%', width: '100%', maxWidth: '600px', margin: '0 auto' }}>
        <div style={{ textAlign: 'center', background: 'linear-gradient(135deg, #7000FF, #FF00E5)', borderRadius: '30px', padding: '50px 30px', boxShadow: '0 20px 50px rgba(112, 0, 255, 0.3)', marginBottom: '40px', position: 'relative', overflow: 'hidden' }}>
          <motion.div animate={{ rotate: 360 }} transition={{ duration: 10, repeat: Infinity, ease: "linear" }} style={{ position: 'absolute', top: '-50px', right: '-50px', width: '200px', height: '200px', background: 'rgba(255,255,255,0.05)', borderRadius: '50%' }} />
          <p style={{ textTransform: 'uppercase', letterSpacing: '2px', fontSize: '0.9rem', opacity: 0.8, marginBottom: '10px' }}>Current Balance</p>
          <h2 style={{ fontSize: '4rem', fontWeight: 800 }}>{balance} <span style={{ fontSize: '1.5rem', opacity: 0.6 }}>GAZ</span></h2>
          <div style={{ marginTop: '20px', display: 'flex', gap: '15px', justifyContent: 'center' }}>
             <button onClick={handleClaim} style={{ padding: '12px 24px', borderRadius: '15px', background: 'white', color: 'black', border: 'none', fontWeight: 700, cursor: 'pointer' }}>Claim Daily</button>
             <button style={{ padding: '12px 24px', borderRadius: '15px', background: 'rgba(255,255,255,0.1)', color: 'white', border: '1px solid rgba(255,255,255,0.2)', fontWeight: 700, cursor: 'pointer' }}>Convert</button>
          </div>
        </div>
        <h3 style={{ marginBottom: '20px', fontSize: '1.5rem' }}>Transaction History</h3>
        <div style={{ background: 'rgba(255,255,255,0.03)', borderRadius: '20px', padding: '10px' }}>
           {[1, 2].map(i => (
             <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '15px', borderBottom: i === 1 ? '1px solid rgba(255,255,255,0.05)' : 'none' }}>
                <div>
                   <p style={{ fontWeight: 600 }}>{i === 1 ? 'System Reward' : 'Virtual Gift'}</p>
                   <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>2026-04-08</p>
                </div>
                <p style={{ color: i === 1 ? 'var(--brand-accent)' : 'var(--brand-danger)', fontWeight: 700 }}>{i === 1 ? '+50' : '-10'} GAZ</p>
             </div>
           ))}
        </div>
      </motion.div>
    );
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'For You':
        return videoFeed.map((post) => (
          <VideoPost key={post.id} data={post} token={sessionToken} />
        ));
      case 'Explore':
        return <ExploreContent />;
      case 'Notifications':
        return <NotificationsContent />;
      case 'Wallet':
        return <WalletContent token={sessionToken} />;
      case 'Comedy':
      case 'Music':
      case 'Gaming':
      case 'Tech':
      case 'Travel':
      case 'Food':
        return videoFeed.map((post) => (
          <VideoPost key={post.id} data={post} token={sessionToken} />
        ));
      case 'Live':
        return (
          <LiveTab token={sessionToken} />
        );
      case 'Profile':
        return (
          <ProfileContent token={sessionToken} onLogout={() => {
            localStorage.removeItem('gipjazes_token');
            setSessionToken('');
            setActiveTab('For You');
          }} />
        );
      default:
        return null;
    }
  };

  return (
    <div className="app-container">
      <AnimatePresence>
        {showSplash && (
          <SplashScreen 
            onComplete={() => {
              setShowSplash(false);
              if (!sessionToken) {
                setIsAuthModalOpen(true);
              }
            }} 
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isAuthModalOpen && <AuthModal isOpen={isAuthModalOpen} onClose={() => setIsAuthModalOpen(false)} onSuccess={handleAuthSuccess} />}
        {isUploadModalOpen && <UploadModal isOpen={isUploadModalOpen} onClose={() => setIsUploadModalOpen(false)} token={sessionToken} />}
      </AnimatePresence>

      <Sidebar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        onOpenUpload={() => setIsUploadModalOpen(true)}
        isOpen={isSidebarOpen}
        setIsOpen={setIsSidebarOpen}
      />
      <div className="main-feed" style={{ display: (activeTab === 'For You' || categories.includes(activeTab)) ? 'flex' : 'block' }}>
        {/* Trending bar removed per request */}
        {!isSidebarOpen && (
          <div className="mobile-header-actions">
            <button className="mobile-action-btn" onClick={() => setIsSidebarOpen(true)}>
              <Menu size={24} />
            </button>
            <div className="brand-text" style={{ fontSize: '1.4rem', fontWeight: 800, color: 'var(--text-main)', letterSpacing: '0.5px', marginLeft: '10px' }}>
               GIPJAZES<span style={{ color: 'var(--brand-primary)' }}>.V</span>
            </div>
            <button className="mobile-action-btn" style={{ marginLeft: 'auto', borderColor: 'var(--brand-accent)' }} onClick={() => setIsUploadModalOpen(true)}>
              <PlusSquare size={22} color="var(--brand-accent)" />
            </button>
          </div>
        )}
        {renderContent()}
      </div>
      {/* BottomNav removed per request - all items moved to Sidebar */}
    </div>
  );
}

export default App;
