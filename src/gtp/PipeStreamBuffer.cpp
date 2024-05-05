// -----------------------------------------------------------------------------
// Copyright 2018-2024 Patrick Näf (herzbube@herzbube.ch)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// -----------------------------------------------------------------------------

// Project includes
#include "PipeStreamBuffer.h"

// System includes
#include <cassert>  // for assert()

// Global constants
// At the moment this is a rather arbitrary value. It was chosen because it is
// small enough that on modern iOS devices it uses up a negligible amount of
// memory, and large enough so that thread context switches due to the buffer
// filling up should occur infrequently.
static const int LINEBUFFERSIZE = 16384;


// -----------------------------------------------------------------------------
/// @brief Initializes a PipeStreamBuffer object.
// -----------------------------------------------------------------------------
PipeStreamBuffer::PipeStreamBuffer() :
  lineBufferSize(LINEBUFFERSIZE),
  lineBuffer(new char[LINEBUFFERSIZE]),
  endReadingPositionNeedsUpdate(false),
  newEndReadingPosition(nullptr),
  currentReadingPositionNeedsUpdate(false),
  newCurrentReadingPosition(nullptr)
{
  // This initialization is not strictly necessary since reading from
  // the buffer cannot occur before it's written to
  memset(this->lineBuffer, 0, this->lineBufferSize);
  
  // The end pointers for reading (egptr) and writing (epptr) must point
  // to a memory location that is 1 character BEHIND the last valid
  // reading/writing location.
  setg(
       this->lineBuffer,
       this->lineBuffer,
       this->lineBuffer);
  setp(
       this->lineBuffer,
       this->lineBuffer + this->lineBufferSize);
}
  
// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PipeStreamBuffer object.
// -----------------------------------------------------------------------------
PipeStreamBuffer::~PipeStreamBuffer()
{
  sync();
  delete[] this->lineBuffer;
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when a reader wants to consume data but there is none
/// available from the current read window. If a writer has already written
/// more data into the internal buffer this method extends the read window and
/// returns immediately. Otherwise this method blocks the caller.
// -----------------------------------------------------------------------------
std::streambuf::int_type PipeStreamBuffer::underflow()
{
  // Acquire the mutex before we change any of our internal state
  std::unique_lock<std::mutex> lock(this->mutexReadWriteLock);
  
  // Signal writing thread in case it is currently blocked by overflow().
  // The writing read will remain blocked until we unlock the mutex.
  this->waitConditionWriteLock.notify_all();
  
  while (! this->endReadingPositionNeedsUpdate && ! this->currentReadingPositionNeedsUpdate)
  {
    // We have to wait until there is some content to read. Entering
    // the wait condition will release the mutex so that the writing
    // thread is unblocked (if it is currently blocked by overflow()).
    // The writing thread will signal us as soon as it has new content,
    // which can happen in two events:
    // - The writing thread is told to sync (e.g. by an std::endl sent
    //   to the ostream, or by flushing the ostream)
    // - The writing thread has completely filled the buffer.
    this->waitConditionReadLock.wait(lock);
  }
  
  // We are now again in possession of the mutex and can start to
  // change our internal state
  setg(
       // Always read from the beginning of the internal buffer
       this->lineBuffer,
       // Unless a change is necessary, continue to read from the current
       // position gptr
       this->currentReadingPositionNeedsUpdate ? this->newCurrentReadingPosition : gptr(),
       // Unless a change is necessary, read up to the current end end
       // position egptr
       this->endReadingPositionNeedsUpdate ? this->newEndReadingPosition : egptr());
  this->endReadingPositionNeedsUpdate = false;
  this->newEndReadingPosition = nullptr;
  this->currentReadingPositionNeedsUpdate = false;
  this->newCurrentReadingPosition = nullptr;
  
  // Release the mutex because we have finished changing our internal
  // state and no longer need it. This will unblock the writing thread
  // (if it is currently blocked by overflow()).
  lock.unlock();
  
  // It's safe to invoke sgetc(), it won't call underflow() again because
  // we now have content in the buffer.
  return sgetc();
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when a writer wants to provide data but the internal
/// buffer is full. This method makes sure that the next reader that underflows
/// will extend the read window to the end of the internal buffer. This method
/// then blocks the caller until a reader has actually consumed everything
/// up to the end of the read windows (= internal buffer).
// -----------------------------------------------------------------------------
std::streambuf::int_type PipeStreamBuffer::overflow(std::streambuf::int_type value)
{
  // Acquire the mutex before we change any of our internal state
  std::unique_lock<std::mutex> lock(this->mutexReadWriteLock);
  
  // The internal buffer is full, we cannot continue until the reading
  // thread has read everything. Notes:
  // - Unlike the implementation of sync(), this must happen
  //   unconditionally.
  // - Read the comments in the member variable section of the class to
  //   understand why we must not invoke setg() at this point.
  this->endReadingPositionNeedsUpdate = true;
  this->newEndReadingPosition = this->lineBuffer + this->lineBufferSize;
  
  // Logically the write position should now match the end position
  // of the buffer
  assert(this->newEndReadingPosition == pptr());
  
  // Signal reading thread in case it is currently blocked by underflow().
  // The reading read will remain blocked until we unlock the mutex.
  this->waitConditionReadLock.notify_all();
  
  // Enter our own wait condition. This will release the mutex and unblock
  // the reading thread. The reading thread will signal us back when it
  // enters underflow() and is about to block again. This happens when it
  // has run out of content to read, i.e. when it has reached the end of
  // the buffer.
  this->waitConditionWriteLock.wait(lock);
  
  // We are now again in possession of the mutex and can continue to
  // change our internal state. Since the reading thread has finished
  // reading to the end of the buffer, we are now free to begin
  // overwriting the old content.
  setp(
       this->lineBuffer,
       this->lineBuffer + this->lineBufferSize);
  
  // The reading thread is still blocked, but when it wakes up the next
  // time it must begin reading from the beginning of the buffer. We don't
  // signal the reading thread here, though, because there's no new
  // content to read yet. The reading thread will be signalled as soon as
  // the next sync or overflow occurs. Notes:
  // - Setting this->newEndReadingPosition here is pointless because the
  //   value we set here will be overwritten by the next sync or overflow.
  //   Nevertheless, setting a new value for this->newEndReadingPosition
  //   here is formally correct, so we do it just in case the
  //   implementation changes in some way in the future.
  this->currentReadingPositionNeedsUpdate = true;
  this->newCurrentReadingPosition = this->lineBuffer;
  this->endReadingPositionNeedsUpdate = true;
  this->newEndReadingPosition = this->lineBuffer;
  
  // Release the mutex because we have finished changing our internal
  // state and no longer need it
  lock.unlock();
  
  // It's safe to invoke sputc(), it won't call overflow() again because
  // the buffer is now empty again.
  sputc(value);
  
  // Although we never want to return EOF, because that indicates failure,
  // there's no sensible way to protect against the caller passing EOF as
  // parameter value.
  return traits_type::to_int_type(value);
};

// -----------------------------------------------------------------------------
/// @brief Is invoked when a writer wants to make data written up until now
/// available to the reader. This method makes sure that the next reader that
/// underflows will extend the read window to the last character currently in
/// the internal buffer. This method does not block the caller.
// -----------------------------------------------------------------------------
int PipeStreamBuffer::sync()
{
  // Acquire the mutex before we change any of our internal state
  std::unique_lock<std::mutex> lock(this->mutexReadWriteLock);
  
  // Check if new content is available. The key to this is the write
  // position pptr, which may, or may not, have advanced since the last
  // sync. Notes:
  // - This check is not necessary for the correctness of the stream
  //   buffer's working, but it is important because it prevents
  //   unnecessary thread context switches.
  // - Read the comments in the member variable section of the class to
  //   understand why we must not invoke setg() at this point, but why
  //   it is safe to check egptr().
  if (pptr() != egptr())
  {
    this->endReadingPositionNeedsUpdate = true;
    this->newEndReadingPosition = pptr();
    
    // Signal reading thread in case it is currently blocked by
    // underflow(). The reading read will remain blocked until we
    // unlock the mutex.
    this->waitConditionReadLock.notify_all();
  }
  else
  {
    // No new content available, therefore no need to signal the
    // reading thread
  }
  
  // Release the mutex because we have finished changing our internal
  // state and no longer need it. This will unblock the reading thread.
  lock.unlock();
  
  // 0 = success, -1 = failure
  return 0;
}

