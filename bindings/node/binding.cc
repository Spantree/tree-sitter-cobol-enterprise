#include "nan.h"
#include "tree_sitter/parser.h"

using namespace v8;

extern "C" TSLanguage *tree_sitter_cobol();

namespace {

NAN_METHOD(New) {}

void Init(Local<Object> exports, Local<Object> module) {
  Local<FunctionTemplate> tpl = Nan::New<FunctionTemplate>(New);
  tpl->SetClassName(Nan::New("Language").ToLocalChecked());
  tpl->InstanceTemplate()->SetInternalFieldCount(1);

  Local<Function> constructor = Nan::GetFunction(tpl).ToLocalChecked();
  Local<Object> instance =
      constructor->NewInstance(Nan::GetCurrentContext()).ToLocalChecked();
  Nan::SetInternalFieldPointer(instance, 0,
                               reinterpret_cast<void *>(tree_sitter_cobol()));
  Nan::Set(instance, Nan::New("name").ToLocalChecked(),
           Nan::New("cobol").ToLocalChecked());
  Nan::Set(module, Nan::New("exports").ToLocalChecked(), instance);
}

NODE_MODULE(tree_sitter_cobol_binding, Init)

}  // namespace
