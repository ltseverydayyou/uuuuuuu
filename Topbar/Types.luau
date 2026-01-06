type Connection<Variant... = ...any> = {
	Disconnect: (self: Connection<Variant...>) -> (),
}



type Signal<Variant... = ...any> = {
	Connect: (self: Signal<Variant...>, func: (Variant...) -> ()) -> Connection<Variant...>,
    Once: (self: Signal<Variant...>, func: (Variant...) -> ()) -> Connection<Variant...>,
	Wait: (self: Signal<Variant...>) -> Variant...,
}



export type IconState = "Deselected" | "Selected" | "Viewing"
export type Events = "selected" | "deselected" | "toggled" | "viewingStarted" | "viewingEnded" | "notified"
export type Alignment = "Left" | "Center" | "Right"
export type EventSource = "User" | "OneClick" | "AutoDeselect" | "HideParentFeature" | "Overflow"
export type Modification = { any }


type StaticFunctions = {
	getIcons: typeof(

		function(): { Icon }
			return (nil :: any) :: { Icon }
		end
	),
	getIcon: typeof(

		function(nameOrUID: string): Icon?
			return nil :: any
		end
	),
	setTopbarEnabled: typeof(

		function(enabled: boolean)

		end
	),
	modifyBaseTheme: typeof(

		function(modifications: { Modification })

		end
	),
	setDisplayOrder: typeof(

		function(order: number)

		end
	),
}

type Methods = {


	setName: typeof(

		function(self: Icon, name: string): Icon
			return nil :: any
		end
	),
	getInstance: typeof(

		function(self: Icon, instanceName: string): Instance?
			return (nil :: any) :: Instance?
		end
	),
	modifyTheme: typeof(

		function(self: Icon, modifications: {Modification} | Modification): Icon
			return nil :: any
		end
	),
	modifyChildTheme: typeof(

		function(self: Icon, modifications: { Modification }): Icon
			return nil :: any
		end
	),
	setEnabled: typeof(

		function(self: Icon, enabled: boolean): Icon
			return nil :: any
		end
	),
	select: typeof(

		function(self: Icon): Icon
			return nil :: any
		end
	),
	deselect: typeof(

		function(self: Icon): Icon
			return nil :: any
		end
	),
	notify: typeof(

		function(self: Icon, clearNoticeEvent: Signal?): Icon
			return nil :: any
		end
	),
	clearNotices: typeof(

		function(self: Icon): Icon
			return nil :: any
		end
	),
	disableOverlay: typeof(

		function(self: Icon, disabled: boolean): Icon
			return nil :: any
		end
	),
	setImage: typeof(

		function(self: Icon, imageId: string | number, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setLabel: typeof(

		function(self: Icon, text: string, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setOrder: typeof(

		function(self: Icon, order: number, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setCornerRadius: typeof(

		function(self: Icon, udim: UDim2, iconState: IconState?): Icon
			return nil :: any
		end
	),
	align: typeof(

		function(self: Icon, alignment: Alignment?): Icon
			return nil :: any
		end
	),
	setWidth: typeof(

		function(self: Icon, minimumSize: number, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setImageScale: typeof(

		function(self: Icon, scale: number, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setImageRatio: typeof(

		function(self: Icon, ratio: number, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setTextSize: typeof(

		function(self: Icon, textSize: number, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setTextColor: typeof(

		function(self: Icon, color: Color3, iconState: IconState?): Icon
			return nil :: any
		end
	),
	setTextFont: typeof(

		function(self: Icon, font: string | Enum.Font, fontWeight: Enum.FontWeight?, fontStyle: Enum.FontSize?, iconState: IconState?): Icon
			return nil :: any
		end
	),
	bindToggleItem: typeof(

		function(self: Icon, guiObjectOrLayerCollector: GuiObject | LayerCollector): Icon
			return nil :: any
		end
	),
	unbindToggleItem: typeof(

		function(self: Icon, guiObjectOrLayerCollector: GuiObject | LayerCollector): Icon
			return nil :: any
		end
	),
	bindEvent: typeof(

		function(self: Icon, event: Events, callback: (...any) -> ()): Icon
			return nil :: any
		end
	),
	unbindEvent: typeof(

		function(self: Icon, event: Events): Icon
			return nil :: any
		end
	),
	bindToggleKey: typeof(

		function(self: Icon, keycode: Enum.KeyCode): Icon
			return nil :: any
		end
	),
	unbindToggleKey: typeof(

		function(self: Icon, keycode: Enum.KeyCode): Icon
			return nil :: any
		end
	),
	call: typeof(

		function(self: Icon, func: (self: Icon) -> (...any), ...: any): Icon
			return nil :: any
		end
	),
	addToJanitor: typeof(

		function(self: Icon, userdata: unknown): Icon
			return nil :: any
		end
	),
	lock: typeof(

		function(self: Icon): Icon
			return nil :: any
		end
	),
	unlock: typeof(

		function(self: Icon): Icon
			return nil :: any
		end
	),
	debounce: typeof(

		function(self: Icon, seconds: number): Icon
			return nil :: any
		end
	),
	autoDeselect: typeof(

		function(self: Icon, enabled: boolean?): Icon
			return nil :: any
		end
	),
	oneClick: typeof(

		function(self: Icon, enabled: boolean?): Icon
			return nil :: any
		end
	),
	setCaption: typeof(

		function(self: Icon, text: string?): Icon
			return nil :: any
		end
	),
	setCaptionHint: typeof(

		function(self: Icon, keyCode: Enum.KeyCode): Icon
			return nil :: any
		end
	),
	setDropdown: typeof(

		function(self: Icon, icons: { Icon }): Icon
			return nil :: any
		end
	),
	joinDropdown: typeof(

		function(self: Icon, parent: Icon): Icon
			return nil :: any
		end
	),
	setMenu: typeof(

		function(self: Icon, icons: { Icon }): Icon
			return nil :: any
		end
	),
	setFixedMenu: typeof(

		function(self: Icon, icons: { Icon }): Icon
			return nil :: any
		end
	),
	joinMenu: typeof(

		function(self: Icon, parentIcon: Icon): Icon
			return nil :: any
		end
	),
	leave: typeof(

		function(self: Icon): Icon
			return nil :: any
		end
	),
	convertLabelToNumberSpinner: typeof(

		function(self: Icon, numberSpinner: any, func: (...any) -> (...any), ...: any): Icon
			return nil :: any
		end
	),
	destroy: typeof(

		function(self: Icon): Icon
			return nil :: any
		end
	),
} & StaticFunctions

type Fields = {

	name: string,
	isSelected: boolean,
	isEnabled: boolean,
	totalNotices: number,
	locked: boolean,


	selected: Signal<EventSource>,
	deselected: Signal<EventSource>,
	toggled: Signal<boolean, EventSource>,
	viewingStarted: Signal,
	viewingEnded: Signal,
	notified: Signal,
}

export type Icon = Methods & StaticFunctions

export type StaticIcon = {
	new: typeof(

		function(): Icon
			return (nil :: any) :: Icon
		end
	),
} & StaticFunctions

return {}
