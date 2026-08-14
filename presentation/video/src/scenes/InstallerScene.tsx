import {AbsoluteFill} from 'remotion';
import {FadeIn, Pill, Screenshot} from '../components';
import {full, label, subtitle, title} from '../styles';

export const InstallerScene = () => (
  <AbsoluteFill style={{...full, padding: '95px 110px', flexDirection: 'row', alignItems: 'center', gap: 100}}>
    <div style={{width: 690}}>
      <FadeIn><div style={label}>安装时只选一次</div></FadeIn>
      <FadeIn delay={12}><h2 style={title}>打开就能用，<br />不反复追问</h2></FadeIn>
      <FadeIn delay={25}><div style={subtitle}>默认选中 Kilo Auto Free；也可以选择 DeepSeek API，之后在应用内填写自己的 Key。视觉辅助和桌面快捷方式都可选。</div></FadeIn>
      <FadeIn delay={42}><div style={{marginTop: 38, display: 'flex', gap: 18, flexWrap: 'wrap'}}><Pill green>免登录</Pill><Pill>不是本地模型</Pill><Pill>首次安装选择</Pill></div></FadeIn>
    </div>
    <FadeIn delay={8}><Screenshot src="installer-model-choice.png" width={980} /></FadeIn>
  </AbsoluteFill>
);
