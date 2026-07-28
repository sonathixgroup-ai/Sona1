import 'package:flutter/material.dart';

class _C {
  static const bg = Color(0xFF050508);
  static const surface = Color(0xFF0C0C12);
  static const surfaceAlt = Color(0xFF111118);
  static const cardBorder = Color(0x14FFFFFF);
  static const violet = Color(0xFF7C5CFF);
  static const gold = Color(0xFFE3B23C);
  static const white = Colors.white;
  static const textMuted = Color(0x66FFFFFF);
  static const textSecondary = Color(0x99FFFFFF);
}

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isSending;
  final VoidCallback onAttach;
  final VoidCallback onAudio;
  final VoidCallback onSecureMessage;
  final VoidCallback onEphemeralToggle;
  final bool isEphemeral;
  final ValueChanged<String>? onTyping;
  final VoidCallback? onInternalNoteToggle;
  final bool isInternalNote;
  const ChatInputBar({super.key, required this.controller, required this.focusNode, required this.onSend, required this.isSending, required this.onAttach, required this.onAudio, required this.onSecureMessage, required this.onEphemeralToggle, required this.isEphemeral, this.onTyping, this.onInternalNoteToggle, this.isInternalNote = false});
  @override State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.isNotEmpty;
  }
  @override void dispose() { widget.controller.removeListener(_onTextChanged); super.dispose(); }
  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (_hasText != has) setState(()=> _hasText = has);
  }

  @override Widget build(BuildContext context) {
    final isNote = widget.isInternalNote;
    return Container(
      decoration: BoxDecoration(
        color: isNote? const Color(0xFF1A1505) : _C.surface,
        border: Border(top: BorderSide(color: isNote? Colors.orange.withOpacity(0.2) : _C.cardBorder)),
      ),
      child: SafeArea(top: false, child: Column(mainAxisSize:MainAxisSize.min, children:[
        // bande actions - scrollable pour éviter overflow millions devices
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal:8,vertical:6),
          child: Row(children:[
            _btn(icon: Icons.attach_file_rounded, label: 'Fichier', onTap: widget.onAttach),
            _btn(icon: widget.isEphemeral? Icons.timer_rounded : Icons.timer_outlined, label: 'Éphémère', onTap: widget.onEphemeralToggle, isActive: widget.isEphemeral, activeColor: _C.violet),
            _btn(icon: Icons.lock_outline_rounded, label: 'Protégé', onTap: widget.onSecureMessage),
            _btn(icon: Icons.mic_none_rounded, label: 'Audio', onTap: widget.onAudio),
            if (widget.onInternalNoteToggle!=null) _btn(icon: Icons.speaker_notes_rounded, label: 'Note', onTap: widget.onInternalNoteToggle!, isActive: isNote, activeColor: Colors.orange),
            if (_hasText) Padding(padding: const EdgeInsets.only(left:8), child: Text('${widget.controller.text.length}',style:const TextStyle(fontSize:9,color:_C.textMuted))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8,0,8,8),
          child: Row(children:[
            Expanded(child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight:40,maxHeight:110),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: widget.onTyping,
                maxLines: null,
                minLines: 1,
                style: const TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.w500),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: isNote? 'Note interne...' : 'Écrire un message...',
                  hintStyle: const TextStyle(color:_C.textMuted,fontSize:12),
                  filled: true,
                  fillColor: isNote? Colors.orange.withOpacity(0.12) : _C.bg,
                  contentPadding: const EdgeInsets.symmetric(horizontal:16,vertical:10),
                  border: OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:const BorderSide(color:_C.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:const BorderSide(color:_C.cardBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide(color: isNote? Colors.orange.withOpacity(0.5) : _C.violet.withOpacity(0.6))),
                ),
              ),
            )),
            const SizedBox(width:8),
            // send - 44 circle
            GestureDetector(
              onTap: (widget.isSending ||!_hasText)? null : widget.onSend,
              child: Container(
                width:42,height:42,
                decoration: BoxDecoration(
                  color: (_hasText &&!widget.isSending)? (isNote? Colors.orange : Colors.white) : _C.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: (_hasText &&!widget.isSending)? Colors.transparent : _C.cardBorder),
                ),
                child: Center(child: widget.isSending? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:_C.textMuted)) : Icon(Icons.send_rounded,size:18,color: (_hasText)? (isNote? Colors.white : Colors.black) : _C.textMuted)),
              ),
            ),
          ]),
        ),
      ])),
    );
  }

  Widget _btn({required IconData icon, required String label, required VoidCallback onTap, bool isActive=false, Color? activeColor}) {
    final c = isActive? (activeColor?? _C.violet) : _C.textMuted;
    return InkWell(onTap:onTap,borderRadius:BorderRadius.circular(8),child:Padding(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:15,color:c),const SizedBox(width:4),Text(label,style:TextStyle(fontSize:9.5,fontWeight:isActive? FontWeight.w700 : FontWeight.w500,color:c))]))); 
  }
}
