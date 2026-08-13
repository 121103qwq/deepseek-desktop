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
    <FadeIn><div style={label}>GitHub Release v0.1.0</div></FadeIn>
    <FadeIn delay={10}><h2 style={{...title, fontSize: 76}}>两个版本，正常安装，也能正常卸载</h2></FadeIn>
    <div style={{display: 'flex', gap: 34, margin: '34px 0'}}>
      <FadeIn delay={22}><Package name="Setup-默认.exe" size="约 36 MB" text="首次启动从国内高速镜像下载 Harness 依赖，显示进度。" /></FadeIn>
      <FadeIn delay={32}><Package name="Offline-Setup.exe" size="约 355 MB" text="内置 Harness 依赖与固定 WebView2 Runtime，安装组件无需另行下载。" /></FadeIn>
    </div>
    <FadeIn delay={46}><div style={{display: 'flex', gap: 20, marginTop: 20}}><Pill>可自定义安装位置</Pill><Pill>注册“已安装的应用”</Pill><Pill green>卸载保留会话与设置</Pill></div></FadeIn>
    <FadeIn delay={62}><div style={{...subtitle, fontSize: 30, marginTop: 46}}>github.com/121103qwq/deepseek-desktop</div></FadeIn>
  </AbsoluteFill>
);
