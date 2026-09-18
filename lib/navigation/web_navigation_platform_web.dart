import 'dart:js_interop';

@JS('window.setIronSamRootLeaveWarningEnabled')
external void _setRootLeaveWarningEnabled(JSBoolean enabled);

@JS('window.ironSamRequestBrowserBack')
external void _requestBrowserBack();

void setRootLeaveWarningEnabled(bool enabled) {
  _setRootLeaveWarningEnabled(enabled.toJS);
}

bool requestBrowserBack() {
  _requestBrowserBack();
  return true;
}
