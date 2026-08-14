import {AbsoluteFill} from 'remotion';
import {FadeIn, Pill} from '../components';
import {colors, full, label, subtitle, title} from '../styles';

const FlowCard = ({title: cardTitle, body, accent = colors.cyan}: {title: string; body: string; accent?: string}) => (
  <div style={{width: 430, minHeight: 270, padding: 30, borderRadius: 26, background: colors.panel, border: `1px solid ${accent}66`, boxShadow: '0 24px 70px #0008'}}>
    <div style={{color: accent, fontSize: 28, fontWeight: 800, marginBottom: 18}}>{cardTitle}</div>
    <div style={{color: colors.white, fontSize: 29, lineHeight: 1.45}}>{body}</div>
  </div>
);

export const VisionScene = () => (
  <AbsoluteFill style={{...full, padding: '90px 110px'}}>
    <FadeIn><div style={label}>可选辅助识图 · 已更新</div></FadeIn>
    <FadeIn delay={10}><h2 style={{...title, fontSize: 72}}>文字模型负责推理，<br />视觉插件负责看图</h2></FadeIn>
    <FadeIn delay={22}><div style={{...subtitle, fontSize: 33}}>dsh-vision-sidecar 0.1.3 默认连接 LLM7.io 的匿名 `default` 路由，不需要视觉 Key，也不下载本地模型。</div></FadeIn>
    <div style={{display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 22, marginTop: 56}}>
      <FadeIn delay={34}><FlowCard title="图片" body="拖入截图、照片或界面" accent="#8fbdff" /></FadeIn>
      <FadeIn delay={44}><div style={{color: colors.cyan, fontSize: 52}}>→</div></FadeIn>
      <FadeIn delay={48}><FlowCard title="LLM7.io default" body="远程视觉描述，不使用本地模型" accent="#66efaa" /></FadeIn>
      <FadeIn delay={58}><div style={{color: colors.cyan, fontSize: 52}}>→</div></FadeIn>
      <FadeIn delay={62}><FlowCard title="Harness" body="把描述交给已选文本模型继续推理" accent="#ffcb70" /></FadeIn>
    </div>
    <FadeIn delay={76}><div style={{display: 'flex', gap: 18, marginTop: 34}}><Pill green>免登录</Pill><Pill>远程服务</Pill><Pill>请留意图片隐私</Pill></div></FadeIn>
  </AbsoluteFill>
);
