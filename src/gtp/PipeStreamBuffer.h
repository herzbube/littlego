// -----------------------------------------------------------------------------
// Copyright 2018 Patrick Näf (herzbube@herzbube.ch)
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


// System includes
#include <streambuf>
#include <mutex>
#include <condition_variable>

// -----------------------------------------------------------------------------
/// @brief The PipeStreamBuffer class is a custom I/O stream buffer that acts
/// as an in-memory pipe. PipeStreamBuffer was designed to enable two threads to
/// communicate with each other via a text-based protocol. There may be other
/// uses. PipeStreamBuffer is thread-safe but @b not reentrant.
///
/// @ingroup gtp
///
/// Two threads that want to communicate with each other bi-directionally need
/// two communication channels: The first channel going from thread A to
/// thread B, the second channel going from thread B to thread A. Both channels
/// have the following characteristics:
/// - The channel can be thought of as a pipe with two end points.
/// - Communication always flows in the same direction from one end point to
///   the other.
/// - PipeStreamBuffer forms the actual pipe that transports the data.
/// - An std::ostream object forms the end point where data enters the pipe.
///   The thread that is pushing data into the pipe is called the writing
///   thread.
/// - An std::istream object forms the end point where data flows out of the
///   pipe. The thread that is getting data from the pipe is called the reading
///   thread.
///
/// PipeStreamBuffer is used like this:
/// @verbatim
/// PipeStreamBuffer channel1;
/// std::ostream channel1_writeEndPoint(&channel1);
/// std::istream channel1_readEndPoint(&channel1);
///
/// PipeStreamBuffer channel2;
/// std::ostream channel2_writeEndPoint(&channel2);
/// std::istream channel2_readEndPoint(&channel2);
///
/// std::thread threadA(threadAMain, channel1_writeEndPoint, channel2_readEndPoint);
/// std::thread threadB(threadBMain, channel2_writeEndPoint, channel1_readEndPoint);
///
/// threadA.join();
/// threadB.join();
/// @endverbatim
// -----------------------------------------------------------------------------
class PipeStreamBuffer : public std::streambuf
{
public:
  PipeStreamBuffer();
  virtual ~PipeStreamBuffer();
  
protected:
  virtual std::streambuf::int_type underflow();
  virtual std::streambuf::int_type overflow(std::streambuf::int_type value);
  virtual int sync();
  
private:
  int lineBufferSize;
  char* lineBuffer;
  
  std::mutex mutexReadWriteLock;
  std::condition_variable waitConditionReadLock;
  std::condition_variable waitConditionWriteLock;
  
  // These member variables are used by the writing thread to communicate
  // to the reading thread when new content is available for reading. The
  // writing thread is not allowed to directly invoke setg() to change
  // egptr because setg() requires the caller to supply a new value for
  // gptr. The writing thread does not want to change gptr, so in theory
  // it could just call gptr() to obtain the current value - but gptr()
  // is NOT protected by mutexReadWriteLock because most of the reading
  // is done by the default implementation of std::streambuf, and that
  // default implementation does not use mutexReadWriteLock when it
  // advances gptr. It is, however, safe to check egptr() in the writing
  // thread because the reading thread (or maybe better: the default
  // implementation of std::streambuf) never changes this pointer on its own,
  // so there's no need to protect it.
  bool endReadingPositionNeedsUpdate;
  char* newEndReadingPosition;
  bool currentReadingPositionNeedsUpdate;
  char* newCurrentReadingPosition;
};
