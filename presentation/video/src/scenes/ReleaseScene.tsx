import {AbsoluteFill, Img, staticFile} from 'remotion';
import {FadeIn, Pill} from '../components';
import {colors, full, label, subtitle, title} from '../styles';

const Package = ({name, size, text}: {name: string; size: string; text: string}) => (
  <div style={{background: colors.panel, border: '1px solid #ffffff1a', borderRadius: 28, padding: 34, width: 700}}>
    <div style={{fontSize: 34, fontWeight: 800}}>{name}</div>
    <div style={{color: colors.cyan, fontSize: 28, margin: '12px 0 20px'}}>{size}</div>
    <div style={{color: colors.muted, fontSize: 28, lineHeight: 1.5}}>{text}</div>
  </div>
);

export const ReleaseScene = () => (
  <AbsoluteFill style={{...full, padding: '90px 130px', justifyContent: 'center'}}>
    <Img src={staticFile('deepseek-black-logo.png')} style={{position: 'absolute', right: 110, top: 78, width: 180, filter: 'invert(1)', opacity: 0.7}} />
    <FadeIn><div style={label}>GitHub Release v0.2.1</div></FadeIn>
    <FadeIn delay={10}><h2 style={{...title, fontSize: 76}}>一个离线包，正常安装，也能正常卸载</h2></FadeIn>
    <div style={{display: 'flex', gap: 34, margin: '34px 0'}}>
      <FadeIn delay={22}><Package name="Windows x64 离线版" size="257.7 MB" text="内置 Harness、Node.js、固定 WebView2 Runtime 和生产依赖，安装完成即可启动。" /></FadeIn>
      <FadeIn delay={32}><Package name="dsh-vision-sidecar 0.1.3" size="LLM7.io · default" text="可选匿名视觉路由，不下载本地模型，不内置共享 API Key。" /></FadeIn>
    </div>
    <FadeIn delay={46}><div style={{display: 'flex', gap: 20, marginTop: 20}}><Pill>可自定义安装位置</Pill><Pill>注册“已安装的应用”</Pill><Pill green>卸载保留会话与设置</Pill></div></FadeIn>
    <FadeIn delay={62}><div style={{...subtitle, fontSize: 30, marginTop: 46}}>github.com/121103qwq/deepseek-desktop · 非官方社区版本</div></FadeIn>
  </AbsoluteFill>
);
