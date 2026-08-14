import {AbsoluteFill} from 'remotion';
import {FadeIn, Screenshot} from '../components';
import {full, label, subtitle, title} from '../styles';

export const DownloadScene = () => (
  <AbsoluteFill style={{...full, padding: '90px 110px'}}>
    <FadeIn><div style={label}>离线版 · 一次安装完成</div></FadeIn>
    <FadeIn delay={10}><h2 style={{...title, fontSize: 72}}>依赖全部随包，<br />不把工作拖到首次启动</h2></FadeIn>
    <FadeIn delay={22}><div style={{...subtitle, fontSize: 34}}>Node.js、Harness、固定版 WebView2 和生产依赖都在安装包内；安装时显示进度，打开后直接进入桌面窗口。</div></FadeIn>
    <div style={{display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 64, marginTop: 58}}>
      <FadeIn delay={28}><Screenshot src="installer-model-choice.png" width={820} /></FadeIn>
      <FadeIn delay={42}><div style={{background: '#111b29', border: '1px solid #42a5ff55', borderRadius: 28, padding: 48, width: 620, boxShadow: '0 32px 100px #000a'}}><div style={{color: '#42a5ff', fontSize: 28, fontWeight: 700}}>DeepSeek Desktop 0.2.1</div><div style={{fontSize: 58, fontWeight: 800, margin: '24px 0 10px'}}>257.7 MB</div><div style={{color: '#a9b7ca', fontSize: 30, lineHeight: 1.45}}>Windows x64 离线安装包<br />完整依赖 · 内置 WebView2</div><div style={{marginTop: 32, height: 16, borderRadius: 99, background: '#213b5d', overflow: 'hidden'}}><div style={{height: '100%', width: '78%', background: '#42a5ff'}} /></div></div></FadeIn>
    </div>
  </AbsoluteFill>
);
