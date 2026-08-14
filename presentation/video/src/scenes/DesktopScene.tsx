import {AbsoluteFill} from 'remotion';
import {FadeIn, Pill, Screenshot} from '../components';
import {full, label, subtitle, title} from '../styles';

export const DesktopScene = () => (
  <AbsoluteFill style={{...full, padding: '70px 90px'}}>
    <div style={{display: 'flex', alignItems: 'end', justifyContent: 'space-between', marginBottom: 42}}>
      <div>
        <FadeIn><div style={label}>内置 WebView2 · 本地 Harness</div></FadeIn>
        <FadeIn delay={10}><h2 style={{...title, fontSize: 72, marginBottom: 8}}>真正的 DeepSeek Desktop 窗口</h2></FadeIn>
        <FadeIn delay={20}><div style={{...subtitle, fontSize: 32}}>默认中文，不会打开外部浏览器；首次关闭可选择最小化到右下角通知区域。</div></FadeIn>
      </div>
      <FadeIn delay={28}><Pill green>本地服务 HTTP 200 · 已实测</Pill></FadeIn>
    </div>
    <FadeIn delay={12}><Screenshot src="deepseek-desktop-main.png" width={1740} height={735} /></FadeIn>
  </AbsoluteFill>
);
