# -*- coding: utf-8 -*-
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: priv/proto/sound.proto

import sys
_b=sys.version_info[0]<3 and (lambda x:x) or (lambda x:x.encode('latin1'))
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from google.protobuf import reflection as _reflection
from google.protobuf import symbol_database as _symbol_database
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()




DESCRIPTOR = _descriptor.FileDescriptor(
  name='priv/proto/sound.proto',
  package='',
  syntax='proto3',
  serialized_options=None,
  serialized_pb=_b('\n\x16priv/proto/sound.proto\"\x89\x01\n\x05Sound\x12\x1b\n\x05noise\x18\x01 \x01(\x0e\x32\x0c.Sound.Noise\x12\x0b\n\x03pan\x18\x02 \x01(\x02\x12\x0c\n\x04size\x18\x03 \x01(\x05\"H\n\x05Noise\x12\x08\n\x04\x46IRE\x10\x00\x12\r\n\tEXPLOSION\x10\x01\x12\x0e\n\nHYPERSPACE\x10\x02\x12\n\n\x06RUMBLE\x10\x03\x12\n\n\x06SAUCER\x10\x04\x62\x06proto3')
)



_SOUND_NOISE = _descriptor.EnumDescriptor(
  name='Noise',
  full_name='Sound.Noise',
  filename=None,
  file=DESCRIPTOR,
  values=[
    _descriptor.EnumValueDescriptor(
      name='FIRE', index=0, number=0,
      serialized_options=None,
      type=None),
    _descriptor.EnumValueDescriptor(
      name='EXPLOSION', index=1, number=1,
      serialized_options=None,
      type=None),
    _descriptor.EnumValueDescriptor(
      name='HYPERSPACE', index=2, number=2,
      serialized_options=None,
      type=None),
    _descriptor.EnumValueDescriptor(
      name='RUMBLE', index=3, number=3,
      serialized_options=None,
      type=None),
    _descriptor.EnumValueDescriptor(
      name='SAUCER', index=4, number=4,
      serialized_options=None,
      type=None),
  ],
  containing_type=None,
  serialized_options=None,
  serialized_start=92,
  serialized_end=164,
)
_sym_db.RegisterEnumDescriptor(_SOUND_NOISE)


_SOUND = _descriptor.Descriptor(
  name='Sound',
  full_name='Sound',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='noise', full_name='Sound.noise', index=0,
      number=1, type=14, cpp_type=8, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='pan', full_name='Sound.pan', index=1,
      number=2, type=2, cpp_type=6, label=1,
      has_default_value=False, default_value=float(0),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='size', full_name='Sound.size', index=2,
      number=3, type=5, cpp_type=1, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
    _SOUND_NOISE,
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=27,
  serialized_end=164,
)

_SOUND.fields_by_name['noise'].enum_type = _SOUND_NOISE
_SOUND_NOISE.containing_type = _SOUND
DESCRIPTOR.message_types_by_name['Sound'] = _SOUND
_sym_db.RegisterFileDescriptor(DESCRIPTOR)

Sound = _reflection.GeneratedProtocolMessageType('Sound', (_message.Message,), dict(
  DESCRIPTOR = _SOUND,
  __module__ = 'priv.proto.sound_pb2'
  # @@protoc_insertion_point(class_scope:Sound)
  ))
_sym_db.RegisterMessage(Sound)


# @@protoc_insertion_point(module_scope)
