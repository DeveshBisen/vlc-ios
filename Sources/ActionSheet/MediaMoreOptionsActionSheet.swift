/*****************************************************************************
 * MediaMoreOptionsActionSheet.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc (VLCMediaMoreOptionsActionSheetDelegate)
protocol MediaMoreOptionsActionSheetDelegate {
    func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool)
    func mediaMoreOptionsActionSheetDidAppeared()
    func mediaMoreOptionsActionSheetShowIcon(for option: OptionsNavigationBarIdentifier)
    func mediaMoreOptionsActionSheetHideIcon(for option: OptionsNavigationBarIdentifier)
    func mediaMoreOptionsActionSheetHideAlertIfNecessary()
    func mediaMoreOptionsActionSheetPresentPopupView(withChild child: UIView)
    func mediaMoreOptionsActionSheetDidSelectChapters()
}

@objc (VLCMediaMoreOptionsActionSheet)
@objcMembers class MediaMoreOptionsActionSheet: MediaPlayerActionSheet {

    // MARK: Instance variables
    weak var moreOptionsDelegate: MediaMoreOptionsActionSheetDelegate?
    var currentMediaHasChapters: Bool = false

    // To be removed when Designs are done for the Filters, Equalizer etc views are added to Figma
    lazy private var mockView: UIView = {
        let v = UIView()
        v.backgroundColor = .green
        v.frame = offScreenFrame
        return v
    }()

    @objc var interfaceDisabled: Bool = false {
        didSet {
            collectionView.visibleCells.forEach {
                if let cell = $0 as? ActionSheetCell, let id = cell.identifier {
                    if id == .interfaceLock {
                        cell.setToggleSwitch(state: interfaceDisabled)
                    } else {
                        cell.alpha = interfaceDisabled ? 0.5 : 1
                    }
                }
            }
            collectionView.allowsSelection = !interfaceDisabled
        }
    }

    override init() {
        super.init()
        mediaPlayerActionSheetDelegate = self
        mediaPlayerActionSheetDataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        removeCurrentChild()
        removeActionSheet()
        moreOptionsDelegate?.mediaMoreOptionsActionSheetDidAppeared()
    }

    func hidePlayer() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetDidAppeared()
    }

// MARK: - Video Filters
    private lazy var videoFiltersView: VideoFiltersView = {
        let videoFiltersView = Bundle.main.loadNibNamed("VideoFiltersView",
                                                        owner: nil,
                                                        options: nil)?.first as! VideoFiltersView
        videoFiltersView.frame = offScreenFrame
        if #available(iOS 13.0, *) {
            videoFiltersView.overrideUserInterfaceStyle = .dark
        }
        videoFiltersView.backgroundColor = PresentationTheme.darkTheme.colors.background
        videoFiltersView.delegate = self
        return videoFiltersView
    }()

// MARK: - Playback Speed View
    private lazy var playbackView: NewPlaybackSpeedView = {
        let playbackSpeedView = Bundle.main.loadNibNamed("NewPlaybackSpeedView",
                                                         owner: nil,
                                                         options: nil)?.first as! NewPlaybackSpeedView

        playbackSpeedView.frame = offScreenFrame
        if #available(iOS 13.0, *) {
            playbackSpeedView.overrideUserInterfaceStyle = .dark
        }
        playbackSpeedView.backgroundColor = PresentationTheme.darkTheme.colors.background
        playbackSpeedView.delegate = self
        return playbackSpeedView
    }()

// MARK: - Sleep Timer
    private lazy var sleepTimerView: SleepTimerView = {
        let sleepTimerView = Bundle.main.loadNibNamed("SleepTimerView",
                                                      owner: nil,
                                                      options: nil)?.first as! SleepTimerView
        sleepTimerView.frame = offScreenFrame
        if #available(iOS 13.0, *) {
            sleepTimerView.overrideUserInterfaceStyle = .dark
        }
        sleepTimerView.backgroundColor = PresentationTheme.darkTheme.colors.background
        sleepTimerView.delegate = self
        return sleepTimerView
    }()

    // MARK: - Instance Methods
    func resetVideoFilters() {
        videoFiltersView.reset()
    }

    func resetPlaybackSpeed() {
        playbackView.reset()
    }

    func resetEqualizer() {
        // FIXME: Call the reset of the equalizer
    }

    func resetSleepTimer() {
        sleepTimerView.reset()
    }

    func getRemainingTime() -> String {
        return sleepTimerView.remainingTime()
    }

// MARK: - Equalizer

    private lazy var equalizerView: EqualizerView = {
        let equalizerView = EqualizerView()
        if #available(iOS 13.0, *) {
            sleepTimerView.overrideUserInterfaceStyle = .dark
        }

        guard let playbackService = PlaybackService.sharedInstance() as? EqualizerViewDelegate else {
            preconditionFailure("PlaybackService should be EqualizerViewDelegate.")
        }
        equalizerView.delegate = playbackService
        return equalizerView
    }()

    func resetOptionsIfNecessary() {
        // FIXME: Reset Equalizer if needed
        videoFiltersView.resetSlidersIfNeeded()
        playbackView.resetSlidersIfNeeded()
    }
}

extension MediaMoreOptionsActionSheet: VideoFiltersViewDelegate {
    func videoFiltersViewShowIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetShowIcon(for: .videoFilters)
    }

    func videoFiltersViewHideIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetHideIcon(for: .videoFilters)
    }
}

extension MediaMoreOptionsActionSheet: NewPlaybackSpeedViewDelegate {
    func newPlaybackSpeedViewHandleOptionChange(title: String) {
        self.headerView.title.text = title
    }

    func newPlaybackSpeedViewShowIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetShowIcon(for: .playbackSpeed)
    }

    func newPlaybackSpeedViewHideIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetHideIcon(for: .playbackSpeed)
    }
}

extension MediaMoreOptionsActionSheet: SleepTimerViewDelegate {
    func sleepTimerViewCloseActionSheet() {
        removeActionSheet()
    }

    func sleepTimerViewShowAlert(message: String, seconds: Double) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        if #available(iOS 13.0, *) {
            alert.view.overrideUserInterfaceStyle = .dark
        }
        alert.view.backgroundColor = PresentationTheme.darkTheme.colors.background
        alert.view.layer.cornerRadius = 15

        self.present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true, completion: {
                self.sleepTimerViewCloseActionSheet()
            })
        }
    }

    func sleepTimerViewHideAlertIfNecessary() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetHideAlertIfNecessary()
    }

    func sleepTimerViewShowIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetShowIcon(for: .sleepTimer)
    }

    func sleepTimerViewHideIcon() {
        moreOptionsDelegate?.mediaMoreOptionsActionSheetHideIcon(for: .sleepTimer)
    }
}

// MARK: - MediaPlayerActionSheetDelegate
extension MediaMoreOptionsActionSheet: MediaPlayerActionSheetDelegate {
    func mediaPlayerActionSheetHeaderTitle() -> String? {
        return NSLocalizedString("MORE_OPTIONS_HEADER_TITLE", comment: "")
    }

    func mediaPlayerDidToggleSwitch(for cell: ActionSheetCell, state: Bool) {
        guard let moreOptionsDelegate = moreOptionsDelegate else {
            preconditionFailure("MediaMoreOptionsActionSheet: MoreOptionsActionSheetDelegate not set")
        }

        if let id = cell.identifier, id == .interfaceLock {
            moreOptionsDelegate.mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: state)
            interfaceDisabled = state
        }
    }
}

// MARK: - MediaPlayerActionSheetDataSource
extension MediaMoreOptionsActionSheet: MediaPlayerActionSheetDataSource {

    private func selectViewToPresent(for cell: MediaPlayerActionSheetCellIdentifier) -> UIView {
        switch cell {
        case .filter:
            return videoFiltersView
        case .playback:
            return playbackView
        case .sleepTimer:
            return sleepTimerView
        case .equalizer:
            return equalizerView
        case .chapters:
            return ChapterDummyView()
        default:
            return mockView
        }
    }

    var configurableCellModels: [ActionSheetCellModel] {
        var models: [ActionSheetCellModel] = []
        MediaPlayerActionSheetCellIdentifier.allCases.forEach {
            if $0 == .chapters && currentMediaHasChapters == false {
                // Do not show the chapters category when there are no chapters.
                return
            }

            let cellModel = ActionSheetCellModel(
                title: String(describing: $0),
                imageIdentifier: $0.rawValue,
                viewToPresent: selectViewToPresent(for: $0),
                cellIdentifier: $0
            )
            if $0 == .interfaceLock {
                cellModel.accessoryType = .toggleSwitch
                cellModel.viewToPresent = nil
            } else if $0 == .equalizer {
                cellModel.accessoryType = .popup
            } else if $0 == .chapters {
                cellModel.accessoryType = .popup
            }
            models.append(cellModel)
        }
        return models
    }
}
