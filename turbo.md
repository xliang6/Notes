# TURBO: Boost WABT Performance using JitBuilder, SPLASH 2018

- We will be completing the JIT implementation
- We will use Mandelbrot as an example

## Dispatching the JIT

- Need to call the JIT from interpreter to compile WASM functions
- Need to call JIT compiled (JITed) functions

```c++
       case Opcode::Call: {
         IstreamOffset offset = ReadU32(&pc);
         CHECK_TRAP(PushCall(pc));
         GOTO(offset);
         break;
       }
```

**Possible Solution:**

```c++
       case Opcode::Call: {
         IstreamOffset offset = ReadU32(&pc);
         Environment::JITedFunction jit_fn;

         if (env_->TryJit(this, offset, &jit_fn)) {
          TRAP_IF(!jit_fn, FailedJITCompilation);
           CHECK_TRAP(PushCall(pc));

           auto result = jit_fn();
           if (result != Result::Ok) {
             // We don't want to overwrite the pc of the JITted function if it traps
             tpc.Reload();

             return result;
           }

           PopCall();
         } else {
           CHECK_TRAP(PushCall(pc));
           GOTO(offset);
         }
         break;
       }

```

## Implement buildIL()

`buildIL()` is the function called by the OMR compiler to generate IL. It should
return `true` when IL generation succeeds, `false` otherwise.

```c++
bool FunctionBuilder::buildIL() {
  setVMState(new TR::VirtualMachineState());

  const uint8_t* istream = thread_->GetIstream();

  workItems_.emplace_back(OrphanBytecodeBuilder(0, const_cast<char*>(ReadOpcodeAt(&istream[fn_->offset]).GetName())),
                          &istream[fn_->offset]);
  AppendBuilder(workItems_[0].builder);

  return false;
}
```

### What's already done

First, we set a new instance of `VirtualMachineState` on the current
`FunctionBuilder` instance. `VirtualMachineState` is used to simulates state
changes that would happen if the function being compiled were to run int the VM.
The rest of the JIT implementation does not use this feature (yet!), so
instantiating the default base class is good enough.

`workItems_` is an array of structs. Each struct holds, among other things, a
pointer to a `BytecodeBuilder` instance. `BytecodeBuilder`s are used to generate
the IL corresponding to a specific instruction/bytecode in a function. The call
to `workItems_.emplace_back()` inserts an instance corresponding to the
first bytecode in the function being compiled. Importantly, notice that the
first argument to `OrphanBytecodeBuilder()` is `0`, indicating that the builder
instance corresponds to the byte code with index 0; the first bytecode in the
function being compiled.

The call to `AppendBuilder()` adds the newly created `BytecodeBuilder` instance
to the internal work list. The work list keeps track of which opcodes from the
function still need to be handled. Internally, the JIT will call
`AppendBuilder()` every time a new bytecode is encountered that requires IL
generation.

### What you need to do

To complete `buildIL()`, you need generate IL for every `BytecodeBuilder` in the
JitBuilder work list. You should use the following helpers provided:

- `GetNextBytecodeFromWroklist()` will return the index (insdie `workItems_`)
of the next bytecode to be handled. If no more bytecodes need to be handled -1
is returned instead.
- `Emit(builder, istream, pc)` will generate IL for a particular opcode on the
specified builder instance. Both the builder and `pc` can be retrieved from the
`workItems_` array using `workItems_[index].builder` and `workItems_[index].pc`.
The `istream` instance that is already provided can be used for the second
argument. `true` is returned if IL generation for the bytecode succeeded,
`false` otherwise.

**Remember** to return `true` if `buildIL()` succeeds and `false` otherwise!

**Possible Solution:**

```c++
bool FunctionBuilder::buildIL() {
  setVMState(new TR::VirtualMachineState());

  const uint8_t* istream = thread_->GetIstream();

  workItems_.emplace_back(OrphanBytecodeBuilder(0, const_cast<char*>(ReadOpcodeAt(&istream[fn_->offset]).GetName())),
                          &istream[fn_->offset]);
  AppendBuilder(workItems_[0].builder);

  int32_t next_index;

  while ((next_index = GetNextBytecodeFromWorklist()) != -1) {
    auto& work_item = workItems_[next_index];

    if (!Emit(work_item.builder, istream, work_item.pc))
      return false;
  }

  return true;
}
```

## Implement a few opcodes

### `Return`

```c++
case Opcode::Return:
  return false;
```

The provided implementation for the `Return` opcode just returns `false`,
causing IL generation, and hence compilation, to fail.

A JIT compiled body is expected to return an `interp::Result` value. For a
normal return (no error or trap), the value `interp::Result::Ok` should be
returned.

Use the JitBuilder `Return()` service to generate IL for the function return.
To return a value, generate the IL representation of the value and pass it as
argument to `Return()`. The `Const()` service generate the IL representation of
a constant value. The service takes as argument the value of the constant,
*which must be of a primitive type*. Use these services to implement the return
opcode.

**Hint:** `interp::Result` is a C++11 enum class and `Result_t` is a typedef for
the underlying integer type of the enum.

**Remember:** JitBuilder services must be called on an *Builder instance, which
in this case is `b`, not `this`

**Remember:** Once IL is generate for `Return`, `Emit()` should return `true` to
signal success

**Possible Solution:**

```c++
case Opcode::Return:
  b->Return(b->Const(static_cast<Result_t>(interp::Result::Ok)));
  return true;
```

### `i32.add`, `i32.sub`, `i32.mul`

```c++
case Opcode::I32Add:
  return false;

case Opcode::I32Sub:
  return false;

case Opcode::I32Mul:
  return false;
```

To implement these opcodes, JitBuilder provides the following services:
`IlBuilder::Add()`, `IlBuilder::Sub()`, and `IlBuilder::Mul()`. For convenience,
the templated helper function `EmitBinaryOp<T>(builder, pc, operation)` takes
care of pop the operands and pushing the result of the operation.

```c++
template <typename T, typename TResult = T, typename TOpHandler>
void EmitBinaryOp(TR::IlBuilder* b, const uint8_t* pc, TOpHandler h);
```

The arguments are:

- `T`: the type of operation being emited (e.g. `int32_t` for 32-bit integer
binary operations)
- `TResult`: the type of the result of the operation (same as `T` by default)
- `TOpHandler`: type of the callable object (object) that generates IL for the
operation
- `builder`: a pointer to the builder object on which pushes and pops should be
generator
- `pc`: the current ("virtual") pc pointing to the instruction for which IL is
being generated
- `operation`: a lambda (or other callable object) that generates the only the
IL for the operation. The lambda is given as arguments the IlValues
corresponding to the operation operands and is expected to return the IlValue
corresponding to the result: `IlValue* lambda(IlValue* lhs, IlValue* rhs)`.

**Hint:** you can pass the current builder `b` to `EmitBinaryOp`

**Hint:** the pc is stored in a variable called `pc`

**Remember:** instead of returning `false` after generating IL for the opcodes,
we only need to `break` out of the `switch` to allow the function to complete.
(The final code just ensures the that the opcodes that follow the current one
are added to the work list for processing.)

**Possible Solution:**

```c++
case Opcode::I32Add:
  EmitBinaryOp<int32_t>(b, pc, [&](TR::IlValue* lhs, TR::IlValue* rhs) {
    return b->Add(lhs, rhs);
  });
  break;

case Opcode::I32Sub:
  EmitBinaryOp<int32_t>(b, pc, [&](TR::IlValue* lhs, TR::IlValue* rhs) {
    return b->Sub(lhs, rhs);
  });
  break;

case Opcode::I32Mul:
  EmitBinaryOp<int32_t>(b, pc, [&](TR::IlValue* lhs, TR::IlValue* rhs) {
    return b->Mul(lhs, rhs);
  });
  break;
```

### `Call`

```c++
case Opcode::Call: {
  auto th_addr = b->ConstAddress(thread_);
  auto offset = b->ConstInt32(ReadU32(&pc));
  auto current_pc = b->Const(pc);

  return false;
}
```

Because of the complexity involved in handling calls (i.e. calling the JIT,
dispatching JITed code vs interpreted code, etc.), we instead call a
*runtime helper* that will handle all this for us. The helper is called,
straightforwardly, `CallHelper`. It takes three arguments: a pointer to the
current `interp::Thread` instance, the offset of the function to be called, and
the current pc. For convenience, these are already provided to you as `th_addr`,
`offset`, and `current_pc`, respectively. `CallHelper` also returns a
`interp::Result`, which must be checked and trap values propagated.

Use the JitBuilder `Call()` service to generate call handling. You can use the
`EmitCheckTrap()` helper to generate IL to handle checking the value returned
by `CallHelper`. As arguments, it takes a builder object, IlValue representing
the value to be checked (return value of `CallHelper`), and `nullptr`.
(Actually, the last argument is a pointer to the pc that must be updated.
However, because we have *already* returned from the called function, there is
no need to update the pc.)

**Possible Solution:**

```c++
case Opcode::Call: {
  auto th_addr = b->ConstAddress(thread_);
  auto offset = b->ConstInt32(ReadU32(&pc));
  auto current_pc = b->Const(pc);

  b->Store("result",
  b->      Call("CallHelper", 3, th_addr, offset, current_pc));

  // Don't pass the pc since a trap in a called function should not update the thread's pc
  EmitCheckTrap(b, b->Load("result"), nullptr);

  break;
}
```

## Implement `EmitBinaryOp`

```c++
template <typename T, typename TResult, typename TOpHandler>
void FunctionBuilder::EmitBinaryOp(TR::IlBuilder* b, const uint8_t* pc, TOpHandler h) {
}
```

To recap, `EmitBinaryOp<T>(builder, pc, operation)` takes care of pop the
operands and pushing the result of the operation. It's arguments are:

- `T`: the type of operation being emited (e.g. `int32_t` for 32-bit integer
binary operations)
- `TResult`: the type of the result of the operation (same as `T` by default)
- `TOpHandler`: type of the callable object (object) that generates IL for the
operation
- `builder`: a pointer to the builder object on which pushes and pops should be
generator
- `pc`: the current ("virtual") pc pointing to the instruction for which IL is
being generated
- `operation`: a lambda (or other callable object) that generates the only the
IL for the operation. The lambda is given as arguments the IlValues
corresponding to the operation operands and is expected to return the IlValue
corresponding to the result: `IlValue* lambda(IlValue* lhs, IlValue* rhs)`.

Use the provided `Push()` and `Pop()` helpers to implement this function. Both
a builder object as first argument and type name as second argument. `Push()`
also takes the IlValue to be "pushed" as third argument. To get the name of type
use the templated helper function `TypeFieldName()`. For example,
`TypeFiledName<int32_t>()` will return the name corresponding to the 32-bit
integer type.

**Possible Solution:**

```c++
template <typename T, typename TResult, typename TOpHandler>
void FunctionBuilder::EmitBinaryOp(TR::IlBuilder* b, const uint8_t* pc, TOpHandler h) {
  auto* rhs = Pop(b, TypeFieldName<T>());
  auto* lhs = Pop(b, TypeFieldName<T>());

  Push(b, TypeFieldName<TResult>(), h(lhs, rhs), pc);
}
```

## Bonus: Implement a virtual stack