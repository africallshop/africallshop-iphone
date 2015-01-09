/* Check for overflow in reading the padding length.
 * Example by Jüri Aedla and Ralph Giles
 * http://lists.xiph.org/pipermail/opus/2012-November/001834.html
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "opus.h"
#include "test_opus_common.h"

#define PACKETSIZE 16909318
#define CHANNELS 2
#define FRAMESIZE 5760

int test_overflow(void)
{
  OpusDecoder *decoder;
  int result;
  int error;

  unsigned char *in = malloc(PACKETSIZE);
  opus_int16 *out = malloc(FRAMESIZE*CHANNELS*sizeof(*out));

  fprintf(stderr, "  Checking for padding overflow... ");
  if (!in || !out) {
    fprintf(stderr, "FAIL (out of memory)\n");
    return -1;
  }
  in[0] = 0xff;
  in[1] = 0x41;
  memset(in + 2, 0xff, PACKETSIZE - 3);
  in[PACKETSIZE-1] = 0x0b;

  decoder = opus_decoder_create(48000, CHANNELS, &error);
  result = opus_decode(decoder, in, PACKETSIZE, out, FRAMESIZE, 0);
  opus_decoder_destroy(decoder);

  free(in);
  free(out);

  if (result != OPUS_INVALID_PACKET) {
    fprintf(stderr, "FAIL!\n");
    test_failed();
  }

  fprintf(stderr, "OK.\n");

  return 1;
}

int main(void)
{
  const char *oversion;
  int tests = 0;;

  iseed = 0;
  oversion = opus_get_version_string();
  if (!oversion) test_failed();
  fprintf(stderr, "Testing %s padding.\n", oversion);

  tests += test_overflow();

  fprintf(stderr, "All padding tests passed.\n");

  return 0;
}
