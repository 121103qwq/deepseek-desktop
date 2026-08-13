import {AbsoluteFill} from 'remotion';
import {FadeIn, Screenshot} from '../components';
import {full, label, subtitle, title} from '../styles';

export const DownloadScene = () => (
  <AbsoluteFill style={{...full, padding: '90px 110px'}}>
    <FadeIn><div style={label}>标准版 · 首次启动</div></FadeIn>
    <FadeIn delay={10}><h2 style={{...title, fontSize: 72}}>缺少依赖时，先确认，再显示下载进度</h2></FadeIn>
    <FadeIn delay={22}><div style={{...subtitle, fontSize: 34}}>从国内高速镜像下载固定组件；下载完成后自动打开，之后启动不再重复。</div></FadeIn>
    <div style={{display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 64, marginTop: 58}}>
      <FadeIn delay={28}><Screenshot src="standard-first-launch-download-prompt.png" width={760} /></FadeIn>
      <FadeIn delay={42}><Screenshot src="standard-first-launch-download-progress.png" width={760} height={520} /></FadeIn>
    </div>
  </AbsoluteFill>
);
