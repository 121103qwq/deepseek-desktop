import {Audio} from '@remotion/media';
import {TransitionSeries, linearTiming} from '@remotion/transitions';
import {fade} from '@remotion/transitions/fade';
import {staticFile} from 'remotion';
import {OpeningScene} from './scenes/OpeningScene';
import {InstallerScene} from './scenes/InstallerScene';
import {DownloadScene} from './scenes/DownloadScene';
import {DesktopScene} from './scenes/DesktopScene';
import {ReleaseScene} from './scenes/ReleaseScene';

export const DeepSeekDesktopTalk = () => (
  <>
    <Audio src={staticFile('narration.wav')} volume={0.92} />
    <TransitionSeries>
      <TransitionSeries.Sequence durationInFrames={300}><OpeningScene /></TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={fade()} timing={linearTiming({durationInFrames: 15})} />
      <TransitionSeries.Sequence durationInFrames={390}><InstallerScene /></TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={fade()} timing={linearTiming({durationInFrames: 15})} />
      <TransitionSeries.Sequence durationInFrames={390}><DownloadScene /></TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={fade()} timing={linearTiming({durationInFrames: 15})} />
      <TransitionSeries.Sequence durationInFrames={420}><DesktopScene /></TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={fade()} timing={linearTiming({durationInFrames: 15})} />
      <TransitionSeries.Sequence durationInFrames={420}><ReleaseScene /></TransitionSeries.Sequence>
    </TransitionSeries>
  </>
);
