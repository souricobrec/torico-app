// Synthetic model only: not durable, not distributed and NEVER a production
// fallback. Models exclusive CAS + read lease for local tests.
export function memoryCertificationAnchor(projectId) {
  if (!projectId.startsWith('demo-')) throw Error('Demo project required');
  let current = null, unavailable = false, readers = 0, writing = false;
  const queue = [];
  const pump = () => {
    if (writing || !queue.length || (queue[0].exclusive && readers)) return;
    const start = item => {
      if (item.exclusive) writing = true; else readers++;
      Promise.resolve().then(item.fn).then(item.resolve, item.reject).finally(() => {
        if (item.exclusive) writing = false; else readers--;
        pump();
      });
    };
    if (queue[0].exclusive) start(queue.shift());
    else while (queue.length && !queue[0].exclusive) start(queue.shift());
  };
  const serial = (fn, exclusive = false) => new Promise((resolve, reject) => {
    queue.push({ fn, exclusive, resolve, reject }); pump();
  });
  const snapshot = () => current ? structuredClone(current) : null;
  return {
    read: () => serial(() => { if (unavailable) throw Error('synthetic outage'); return snapshot(); }),
    withCurrent: (project, work) => serial(async () => {
      if (unavailable || project !== projectId) throw Error('synthetic read failure');
      return work(snapshot());
    }),
    advance: (expectedGeneration, next) => serial(() => {
      if (unavailable) throw Error('synthetic write failure');
      if ((current?.generation ?? 0) !== expectedGeneration || next.projectId !== projectId ||
          next.generation !== expectedGeneration + 1 || !Number.isSafeInteger(next.generation) ||
          !['active', 'revoked'].includes(next.state) || !/^[a-f0-9]{64}$/.test(next.certificateId)) {
        throw Object.assign(new Error('anchor_cas_conflict'), { status: 409 });
      }
      current = structuredClone(next); return snapshot();
    }, true),
    failReads: value => { unavailable = value; },
  };
}
