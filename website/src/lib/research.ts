export type Reference = {
  id: string;
  authors: string;
  title: string;
  source: string;
  year: number;
};

/** Peer-reviewed sources cited across the site. Links go to a PubMed search for the exact title. */
export const references: Reference[] = [
  {
    id: "nutt2011",
    authors: "Nutt JG, Bloem BR, Giladi N, Hallett M, Horak FB, Nieuwboer A",
    title: "Freezing of gait: moving forward on a mysterious clinical phenomenon",
    source: "Lancet Neurology 10(8):734–744",
    year: 2011,
  },
  {
    id: "macht2007",
    authors: "Macht M, Kaussner Y, Möller JC, et al.",
    title: "Predictors of freezing in Parkinson's disease: a survey of 6,620 patients",
    source: "Movement Disorders 22(7):953–956",
    year: 2007,
  },
  {
    id: "bloem2004",
    authors: "Bloem BR, Hausdorff JM, Visser JE, Giladi N",
    title: "Falls and freezing of gait in Parkinson's disease: a review of two interconnected, episodic phenomena",
    source: "Movement Disorders 19(8):871–884",
    year: 2004,
  },
  {
    id: "spaulding2013",
    authors: "Spaulding SJ, Barber B, Colby M, Cormack B, Mick T, Jenkins ME",
    title: "Cueing and gait improvement among people with Parkinson's disease: a meta-analysis",
    source: "Archives of Physical Medicine and Rehabilitation 94(3):562–570",
    year: 2013,
  },
  {
    id: "nieuwboer2007",
    authors: "Nieuwboer A, Kwakkel G, Rochester L, et al.",
    title: "Cueing training in the home improves gait-related mobility in Parkinson's disease: the RESCUE trial",
    source: "Journal of Neurology, Neurosurgery & Psychiatry 78(2):134–140",
    year: 2007,
  },
  {
    id: "keus2014",
    authors: "Keus S, Munneke M, Graziano M, et al.",
    title: "European Physiotherapy Guideline for Parkinson's Disease",
    source: "KNGF / ParkinsonNet",
    year: 2014,
  },
  {
    id: "bachlin2010",
    authors: "Bächlin M, Plotnik M, Roggen D, et al.",
    title: "Wearable assistant for Parkinson's disease patients with the freezing of gait symptom",
    source: "IEEE Transactions on Information Technology in Biomedicine 14(2):436–446",
    year: 2010,
  },
  {
    id: "ginis2018",
    authors: "Ginis P, Nackaerts E, Nieuwboer A, Heremans E",
    title: "Cueing for people with Parkinson's disease with freezing of gait: a narrative review of the state-of-the-art and novel perspectives",
    source: "Annals of Physical and Rehabilitation Medicine 61(6):407–413",
    year: 2018,
  },
];

export function refUrl(r: Reference) {
  return `https://pubmed.ncbi.nlm.nih.gov/?term=${encodeURIComponent(`"${r.title}"`)}`;
}

export function refNumber(id: string) {
  return references.findIndex((r) => r.id === id) + 1;
}
