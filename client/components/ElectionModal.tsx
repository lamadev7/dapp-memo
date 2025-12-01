import React, { useState, useEffect } from 'react';
import { useDispatch } from 'react-redux';
import { Modal } from 'react-bootstrap';
import Select from "react-select";
import { toast } from 'react-toastify';
import { DISTRICT, ELECTION_TYPE, ElectionSmartContract } from '../constants';
import { createElection } from '../utils/action';
import Avatar from './Avatar';
import { BsFacebook, BsInstagram, BsTwitter } from 'react-icons/bs';
import { getCandidateList, getElectionList } from '../utils';
import moment from 'moment';
import { setCurrentElection } from '../redux/reducers/commonReducer';
import { getStorage } from '../services';

const currentDate = new Date();
const defaultDate = `${currentDate.getFullYear()}-${currentDate.getMonth() + 1}-${currentDate.getDate()}T${currentDate.getHours()}:${currentDate.getMinutes()}`;
const defaultElectionData = {
  id: "",
  title: "",
  description: "",
  startTime: defaultDate,
  endTime: defaultDate,
  electionType: null,
  electionImages: null,
  selectedCandidateAddresses: [],
  boothPlace: "",
  position: ""
}
const districtElectionPosition = [
  { label: "Mayor", value: "mayor" },
  { label: "Deputy Mayor", value: "deput_mayor" },
  { label: "Ward Councilor", value: "ward_councilor" }
]
let originalCandidateList = [];

const ElectionModal = ({ show, setShowCreateElectionModal }) => {
  const [election, setElection] = useState({ ...defaultElectionData });
  const [electionList, setElectionList] = useState([]);
  const [_candidateLists, setCandidateList] = useState([])
  const [isDisabled, setDisabled] = useState(true);
  const [loading, setLoading] = useState(false);
  const loggedInAccountAddress = getStorage("loggedInAccountAddress");
  const [openCandidateModal, setOpenCandidateModal] = useState(false);
  const [recentlyCreatedElection, setRecentlyCreatedElection] = useState(null);
  const dispatch = useDispatch();

  const fetchData = async () => {
    const elections = await getElectionList();
    const candidateLists = await getCandidateList();
    const currentElection = elections?.at(-1)

    originalCandidateList = [...candidateLists];
    setRecentlyCreatedElection(currentElection);
    setCandidateList(candidateLists);
    setElectionList(elections);

    if (!Object.keys(currentElection ?? {})?.length) return;
    const { title, description, startTime, endTime, electionType }: any = currentElection;
    dispatch(setCurrentElection({ title, description, startTime, endTime, electionType }));
  }

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    if (!recentlyCreatedElection?.candidates?.length && moment.unix(recentlyCreatedElection?.endTime).isBefore(moment().unix())) {
      setElection({ ...election, electionType: recentlyCreatedElection?.electionType });
      setShowCreateElectionModal(false);
      setOpenCandidateModal(true);
    };
  }, [recentlyCreatedElection]);

  useEffect(() => {
    setDisabled(
      !election.title || !election.description || !election.startTime || !election.endTime
    );
  }, [election.title, election.description, election.startTime, election.endTime]);

  const onChange = (name: string, value: string) => {
    setElection({ ...election, [name]: value });

    if (name === "electionType") {
      setElection({ ...defaultElectionData, electionType: value });
    }
  };

  console.log({ election })
  const onCreate = async () => {
    setLoading(true);

    try {
      let { title, description, startTime, endTime, electionType, electionImages, selectedCandidateAddresses, boothPlace, position } = election;
      console.log({ title, description, startTime, endTime, electionType, electionImages, selectedCandidateAddresses, boothPlace, position })
      const formData = new FormData();

      if (!moment(startTime).isAfter(new Date()) || !moment(startTime).isBefore(endTime)) {
        setLoading(false);
        return toast.error("Please give correct datetime !")
      }

      Array.from(electionImages).forEach((file: any) => {
        formData.append("images", file);
      })

      await createElection({ title, description, startTime, endTime });
      // const { url }: any = await getHostedUrl(formData);
      // const galleryImagesUrl = url;

      const galleryImagesUrl = [];

      await ElectionSmartContract.methods.createElection(
        title,
        description,
        moment(startTime).unix(),
        moment(endTime).unix(),
        electionType.value === "District" ? 3 : electionType.value === "Local" ? 2 : 1,
        galleryImagesUrl,
        selectedCandidateAddresses,
        boothPlace,
        position
      ).send({ from: loggedInAccountAddress });

      setShowCreateElectionModal(false);
      setOpenCandidateModal(true);

      fetchData();

      toast.success(`New ${election?.electionType?.toLowerCase()} election created successfully.`);
    } catch (error) {
      console.error(error);
      toast.error("Failed to create election !");
    }
    setLoading(false);
  }

  const onCandidateSelected = (checked: boolean, details: any) => {
    let temp = [...election.selectedCandidateAddresses];

    // only allow one person from specific party 
    const isCandidateAlreadySelected = temp.some((address: any) => address === details?.user?.id);
    if(isCandidateAlreadySelected) return toast.error("Candidate already selected !");

    if (!checked) temp = temp.filter((address: any) => address !== details?.user?.id);
    else temp.push(details?.user?.id);

    setElection({ ...election, selectedCandidateAddresses: [...temp] });
  }

  const onOpenCandidateModal = () => {
    setOpenCandidateModal(!openCandidateModal);
  }

  const handleClose = () => {
    setElection(defaultElectionData);
    setShowCreateElectionModal(!show);
    setCandidateList([...originalCandidateList]);
  }

  const districtOptions = [];
  Object.keys(DISTRICT).forEach((key) => DISTRICT[key].forEach((options: object) => districtOptions.push(options)));

  return (
    <>
      <Modal show={openCandidateModal} size='xl'>
        <Modal.Body className='px-4'>
          <h4 className='my-3'>Candidate Selection</h4>
          {(election?.electionType === "1" || election?.electionType === "3") &&
            <div className='flex sm:flex-row xsm:flex-col'>
              <div className='w-[300px] my-4'>
                <span>Select Candidate Position</span>
                <Select
                  className='mt-1'
                  options={districtElectionPosition}
                  placeholder="Select Position"
                  onChange={({ value }) => {
                    setElection({ ...election, position: value });
                  }}
                  isDisabled={!election?.boothPlace}
                />
              </div>
              <div className='w-[300px] my-4 ml-4'>
                <span>Select District</span>
                <Select
                  className='mt-1'
                  options={districtOptions}
                  placeholder="Select District"
                  onChange={({ value }) => {
                    setElection({ ...election, boothPlace: value });
                  }}
                />
              </div>
            </div>
          }
          <div className='flex flex-wrap'>
            {(_candidateLists && _candidateLists?.length > 0) ?
              _candidateLists.map((details: any) => {
                const formattedEmail = details?.user?.email.split("@")[0];
                const isDisabledCheckbox = !election?.position;
                
                return (
                  <div className='user__card h-[180px] w-[340px] px-2 mb-3 mr-4 max-[500px]:w-[500px] max-[400px]:w-full bg-slate-100 rounded-[12px] hover:bg-red-20'>
                    <div className={`absolute m-2 p-2 shadow-lg border-[1px] rounded-circle h-[45px] w-[45px] flex justify-center items-center ${isDisabledCheckbox ? "bg-gray-100" : "bg-white border-slate-500"}`}>
                      <input
                        className={`h-[20px] w-[20px] cursor-pointer ${isDisabledCheckbox ? "cursor-default" : "cursor-pointer"}`}
                        type="checkbox"
                        onClick={(e: any) => {
                          onCandidateSelected(e.target.checked, details);
                        }}
                        key={details?.user?.citizenshipNumber}
                        disabled={!election?.position}
                        checked={election?.selectedCandidateAddresses?.find((address: any) => address === details?.user?.id)}
                      />
                    </div>
                    <div className='flex justify-around items-center mt-4'>
                      <div className='col1 flex-col'>
                        <Avatar src={details?.user?.profileUrl} className={''} alt={'img'} size={'xl'} border={0} />
                        <div className='social__media flex justify-center mt-3'>
                          <BsFacebook className='cursor-pointer hover:text-md hover:text-red-500 hover:animate-bounce' />
                          <BsInstagram className='mx-4 cursor-pointer hover:text-md hover:text-red-500 hover:animate-bounce' />
                          <BsTwitter className='cursor-pointer hover:text-md hover:text-red-500 hover:animate-bounce' />
                        </div>
                      </div>
                      <div className='col2 pr-1 h-fit flex-xl-column text-[15px] ml-1'>
                        <div>Name: {details?.user?.fullName}</div>
                        <div>Citizenship No: {details?.user?.citizenshipNumber}</div>
                        <div>Age: {details?.user?.age}</div>
                        <div>Party: {details?.partyName}</div>
                        <div>Email: {formattedEmail}</div>
                      </div>
                    </div>
                  </div >
                )
              }) : "No Candidates Available !"}
          </div >
        </Modal.Body >
        <Modal.Footer>
          <button
            className="btn bg-light px-4"
            onClick={() => {setOpenCandidateModal(false);}}
          >Close</button>
        </Modal.Footer >
      </Modal >
      <Modal show={show} centered>
        <Modal.Header className='pt-4 pb-3 px-4'>
          <h5>Create new election</h5>
        </Modal.Header>
        <Modal.Body>
          <div className='px-2'>
            <div className='w-full mb-4'>
              <div className='w-100'>
                <label>Election Type</label>
                <Select
                  options={ELECTION_TYPE}
                  className="mr-2 mt-1"
                  placeholder={<div>Select Type</div>}
                  onChange={(item: any) => onChange("electionType", item.value)}
                />
              </div>
            </div>
            <div className='flex flex-column'>
              <label>Election Title</label>
              <input
                type="text"
                className='form-control mt-2 mb-4 shadow-none'
                onChange={(e) => onChange("title", e.target.value)} />
            </div>
            <div className='flex flex-column'>
              <label>Short Election Description</label>
              <textarea
                className='form-control mt-2 mb-4 shadow-none h-[130px]'
                onChange={(e) => onChange("description", e.target.value)}>
              </textarea>
            </div>
            <div className='hold__date flex '>
              <div className='w-50 mr-2'>
                <span>Start Date & time</span>
                <input
                  type="datetime-local"
                  className="form-control mt-1 shadow-none"
                  value={election.startTime}
                  onChange={(e) => onChange("startTime", e.target.value)} />
              </div>
              <div className='w-50 ml-2'>
                <span>End Date & time</span>
                <input
                  type="datetime-local"
                  value={election.endTime}
                  className="form-control mt-1 shadow-none"
                  onChange={(e) => onChange("endTime", e.target.value)} />
              </div>
            </div>
            <div className='w-full mt-4'>
              <label>Choose election images</label>
              <input
                className='form-control mt-2'
                type="file"
                name='files'
                multiple
                onChange={(e: any) => setElection({ ...election, electionImages: e.target.files })}
              />
            </div>
            <button
              className={`h-fit w-full flex items-center mt-4 rounded-3 border border-1 border-slate-400 bg-slate-200 ${election?.electionType ? "cursor-pointer hover:bg-slate-100" : "hidden"}`}
              onClick={onOpenCandidateModal}
            >
              <span className='flex-shrink px-[14px] text-dark'>Open modal</span>
              <div className='bg-white flex-1 text-start px-3 py-[8px] text-slate-800'>{
                !_candidateLists?.length ? "Candidates not found !" :
                  (!election?.selectedCandidateAddresses?.length ? "Choose candidates" : `Selected Candidates: ${election.selectedCandidateAddresses?.length}`)
              }</div>
            </button>
          </div >
        </Modal.Body >
        <Modal.Footer>
          <button className='me-4' onClick={handleClose}>Close</button>
          <button
            className={`bg-blue-900 text-light py-1 w-[130px] rounded-[5px] hover:opacity-75 flex justify-center items-center ${(isDisabled || loading) && 'opacity-75 cursor-default'}`}
            onClick={onCreate}
            disabled={isDisabled || loading}
          >
            {loading ? "Saving" : "Register"}
          </button>
        </Modal.Footer>
      </Modal >
    </>
  )
}

export default ElectionModal;
