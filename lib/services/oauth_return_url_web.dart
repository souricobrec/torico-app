import 'dart:js_interop';

@JS('window.history.replaceState')
external void _replaceState(JSAny? state, JSString title, JSString url);

@JS('window.history.state')
external JSAny? get _historyState;

void replaceOAuthReturnUrl(Uri uri) {
  _replaceState(_historyState, ''.toJS, uri.toString().toJS);
}
