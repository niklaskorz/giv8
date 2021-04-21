{.passL: "-lv8 -lv8_libplatform".}
{.passC: "-DV8_COMPRESS_POINTERS -DV8_31BIT_SMIS_ON_64BIT_ARCH".}

type UniquePtr*[T] {.importcpp: "std::unique_ptr", header: "<memory>".} = object

{.push header: "<v8.h>".}
type
  Platform* {.importcpp: "v8::Platform".} = object
  CreateParams* {.importcpp: "v8::Isolate::CreateParams".} = object
    array_buffer_allocator: ptr Allocator
  Allocator* {.importcpp: "v8::ArrayBuffer:Allocator".} = object
  Isolate* {.importcpp: "v8::Isolate".} = object
  IsolateScope* {.importcpp: "v8::Isolate::Scope".} = object
  HandleScope* {.importcpp: "v8::HandleScope".} = object
  MaybeLocal*[T] {.importcpp: "v8::MaybeLocal"} = object
  Local*[T] {.importcpp: "v8::Local"} = object
  Context* {.importcpp: "v8::Context".} = object
  ContextScope* {.importcpp: "v8::Context::Scope".} = object
  String* {.importcpp: "v8::String".} = object
  Script* {.importcpp: "v8::Script".} = object
  Value* {.importcpp: "v8::Value".} = object
  Utf8Value* {.importcpp: "v8::String::Utf8Value".} = object


proc initializeICUDefaultLocation*(path: cstring): void {.importcpp: "v8::V8::InitializeICUDefaultLocation(@)".}
proc initializeExternalStartupData*(path: cstring): void {.importcpp: "v8::V8::InitializeExternalStartupData(@)".}
proc initializePlatform*(p: ptr Platform): void {.importcpp: "v8::V8::InitializePlatform(@)".}
proc initialize*(): void {.importcpp: "v8::V8::Initialize(@)".}

proc initCreateParams*(): CreateParams {.importcpp: "v8::Isolate::CreateParams{@}", constructor.}
proc newDefaultAllocator*(): ptr Allocator {.importcpp: "v8::ArrayBuffer::Allocator::NewDefaultAllocator(@)".}
proc newIsolate*(params: CreateParams): ptr Isolate {.importcpp: "v8::Isolate::New(@)".}

proc dispose*(isolate: ptr Isolate): void {.importcpp: "#.Dispose(@)".}
proc dispose*(): void {.importcpp: "v8::V8::Dispose(@)".}
proc shutdownPlatform*(): void {.importcpp: "v8::V8::ShutdownPlatform(@)".}

proc constructIsolateScope*(isolate: ptr Isolate): IsolateScope {.importcpp: "v8::Isolate::Scope{@}", constructor.}
proc constructHandleScope*(isolate: ptr Isolate): HandleScope {.importcpp: "v8::HandleScope{@}", constructor.}
proc newContext*(isolate: ptr Isolate): Local[Context] {.importcpp: "v8::Context::New(@)".}
proc constructContextScope*(context: Local[Context]): ContextScope {.importcpp: "v8::Context::Scope{@}", constructor.}
proc newFromUtf8*(isolate: ptr Isolate, src: cstring): MaybeLocal[String] {.importcpp: "v8::String::NewFromUtf8(#, #, v8::NewStringType::kNormal)".}
proc compile*(context: Local[Context], src: Local[String]): MaybeLocal[Script] {.importcpp: "v8::Script::Compile(@)".}
proc run*(script: Local[Script], context: Local[Context]): MaybeLocal[Value] {.importcpp: "#->Run(@)".}
proc toLocalChecked*[T](m: MaybeLocal[T]): Local[T] {.importcpp: "#.ToLocalChecked(@)".}
proc construcUtf8Value*(isolate: ptr Isolate, Value: Local[Value]): Utf8Value {.importcpp: "v8::String::Utf8Value{@}", constructor.}
proc toString(value: Utf8Value): cstring {.importcpp: "*#".}
{.pop.}

{.push header: "<libplatform/libplatform.h>".}
proc newDefaultPlatform*(): UniquePtr[Platform] {.importcpp: "v8::platform::NewDefaultPlatform(@)".}
proc get*(p: UniquePtr[Platform]): ptr Platform {.importcpp: "#.get(@)".}
{.pop.}

import os

proc inScope(isolate: ptr Isolate) =
  let isolateScope = constructIsolateScope(isolate)
  let handleScope = constructHandleScope(isolate)
  let context = newContext(isolate)
  let contextScope = constructContextScope(context)
  let source = newFromUtf8(isolate, "5 * 8").toLocalChecked()
  let script = compile(context, source).toLocalChecked()
  let result = script.run(context).toLocalChecked()
  let utf8 = construcUtf8Value(isolate, result)
  echo utf8.toString()

when isMainModule:
  initializeICUDefaultLocation(paramStr(0))
  initializeExternalStartupData(paramStr(0))
  let platform = newDefaultPlatform()
  initializePlatform(platform.get())
  initialize()

  var createParams: CreateParams
  createParams.arrayBufferAllocator = newDefaultAllocator()

  let isolate = newIsolate(createParams)
  inScope(isolate)
  isolate.dispose()
  dispose()
  shutdownPlatform()
  dealloc(createParams.arrayBufferAllocator)
