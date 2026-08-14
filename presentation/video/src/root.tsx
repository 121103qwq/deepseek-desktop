import {Composition, Folder} from 'remotion';
import {DeepSeekDesktopTalk} from './video';
import {OpeningScene} from './scenes/OpeningScene';
import {InstallerScene} from './scenes/InstallerScene';
import {DownloadScene} from './scenes/DownloadScene';
import {VisionScene} from './scenes/VisionScene';
import {DesktopScene} from './scenes/DesktopScene';
import {ReleaseScene} from './scenes/ReleaseScene';

export const VideoRoot = () => (
  <>
    <Folder name="DeepSeek-Desktop-Scenes">
      <Composition id="OpeningScene" component={OpeningScene} durationInFrames={210} fps={30} width={1920} height={1080} />
      <Composition id="InstallerScene" component={InstallerScene} durationInFrames={270} fps={30} width={1920} height={1080} />
      <Composition id="DownloadScene" component={DownloadScene} durationInFrames={240} fps={30} width={1920} height={1080} />
      <Composition id="VisionScene" component={VisionScene} durationInFrames={240} fps={30} width={1920} height={1080} />
      <Composition id="DesktopScene" component={DesktopScene} durationInFrames={300} fps={30} width={1920} height={1080} />
      <Composition id="ReleaseScene" component={ReleaseScene} durationInFrames={300} fps={30} width={1920} height={1080} />
    </Folder>
    <Composition id="DeepSeekDesktopTalk" component={DeepSeekDesktopTalk} durationInFrames={2085} fps={30} width={1920} height={1080} />
  </>
);
